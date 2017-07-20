package Krawfish::Koral::Query::Constraints;
use parent 'Krawfish::Koral::Query';
use Krawfish::Query::Constraints;
use Krawfish::Query::Constraint::Position;
use Krawfish::Util::Bits;
use Krawfish::Log;
use v5.10;
use strict;
use warnings;

use constant DEBUG => 0;

# TODO:
#   Normalization phase can be optimized.

# Constructor
sub new {
  my $class = shift;
  bless {
    constraints => shift,
    operands => [@_]
  }, $class;
};


sub type { 'constraints' };


# List of ordered constraints
sub constraints {
  my $self = shift;
  if (@_) {
    $self->{constraints} = shift;
  };
  return $self->{constraints};
};


# Normalize constraints
sub normalize {
  my $self = shift;

  # Normalize both operands
  my ($first, $second);
  unless ($first = $self->{operands}->[0]->normalize) {
    $self->copy_info_from($self->{operands}->[0]);
    return;
  };

  unless ($second = $self->{operands}->[1]->normalize) {
    $self->copy_info_from($self->{operands}->[1]);
    return;
  };

  $self->operands([$first, $second]);

  # TODO:
  #   Merge position constraints!
  # TODO:
  #   When an inbetween constraint and a position constraint exists,
  #   make sure they don't contradict, like
  #   position=precedesDirectly and inBetween=3-6
  # TODO:
  #   Reorder subs!
  # TODO:
  #   Ensure no constraints are doubled if consecutive
  # TODO:
  #   not_between and in_between has a c_position('precedes','succeeds')
  #   constraint in front.

  my @constraints = ();
  my $last = '';
  foreach (@{$self->constraints}) {

    # Ignore idempotence
    my $c = $_->to_string;
    next if $last eq $c;
    $last = $c;

    # Plan may result in a null-query
    # TODO:
    #   Copy warnings etc.
    #   Return undef, if the query is null
    my $norm = $_->normalize or next;

    push @constraints, $norm;
  };

  # Set constraints
  $self->constraints(\@constraints);

  # There is only a single constraint
  if (@constraints == 1) {

    my $constr = $constraints[0];

    # Special normalization for position
    if ($constr->type eq 'constr_pos') {
      $self = $self->_normalize_single_position;
    };
  };

  return $self;
};



# Normalize position, if it's only a single constraint
sub _normalize_single_position {
  my $self = shift;

  my $frames = $self->constraints->[0]->frames;

  # This may be reducible to first span
  state $valid_frames =
    PRECEDES | PRECEDES_DIRECTLY | STARTS_WITH | IS_AROUND | ENDS_WITH |
    SUCCEEDS_DIRECTLY | SUCCEEDS;

  my ($first, $second) = @{$self->operands};

  if ($second->is_null) {
    print_log('kq_constr', 'Try to eliminate null query') if DEBUG;

    # Frames has at least one match with valid frames
    if ($frames & $valid_frames) {
      if (DEBUG) {
        print_log('kq_constr', 'Frames match valid frames');
        print_log('kq_constr', '  ' . bitstring($frames) . ' & ');
        print_log('kq_constr', '  ' . bitstring($valid_frames) . ' = true');
      };

      # Frames has no match with invalid frames
      unless ($frames & ~$valid_frames) {
        if (DEBUG) {
          print_log('kq_constr', 'Frames don\'t match invalid frames');
          print_log('kq_constr', '  ' . bitstring($frames) . ' & ');
          print_log('kq_constr', '  ' . bitstring(~$valid_frames) . ' = false');
          print_log('kq_constr', 'Can eliminate null query');
        };

        # Return the first query
        return $first;
      };
    };

    $self->error(000, 'Null elements in certain positional queries are undefined');
    return;
  };

  return $self;
};


# Optimize the query for an index
sub optimize {
  my ($self, $index) = @_;

  # Optimize operands
  my $first = $self->{operands}->[0]->optimize($index);
  if ($first->max_freq == 0) {
    return Krawfish::Query::Nothing->new;
  };

  my $second = $self->{operands}->[1]->optimize($index);
  if ($second->max_freq == 0) {
    return Krawfish::Query::Nothing->new;
  };

  # Optimize constraints
  my @constraints = ();
  foreach (@{$self->constraints}) {
    my $opt = $_->optimize($index) or next;
    push @constraints, $opt;
  };

  # Create constraint
  return Krawfish::Query::Constraints->new(
    \@constraints,
    $first,
    $second
  );
};


# Return true if the query can be unsorted
sub maybe_unsorded {
  ...
};


# Serialize to KoralQuery
sub to_koral_fragment {
  ...
};


# Stringification
sub to_string {
  my $self = shift;
  my $str = 'constr(';
  $str .= join(',', map { $_->to_string } @{$self->{constraints}});
  $str .= ':';
  $str .= join ',', map { $_->to_string } @{$self->{operands}};
  return $str . ')';
};


1;
