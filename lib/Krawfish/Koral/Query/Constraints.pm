package Krawfish::Koral::Query::Constraints;
use parent 'Krawfish::Koral::Query';
use Krawfish::Query::Constraints;
use Krawfish::Query::Constraint::Position;
use Krawfish::Util::Bits;
use Krawfish::Log;
use v5.10;
use strict;
use warnings;

use constant DEBUG => 1;

# TODO:
#   In the logical planning phase
#   - ensure no constraints are doubled
#   - position constraints are merged
#   - not_between has a c_position('precedes','follows') constraint
#     in front.

sub new {
  my $class = shift;
  bless {
    constraints => shift,
    first => shift,
    second => shift
  }
};


sub to_koral_fragment {
  ...
 };

sub type { 'constraints' };

sub constraints {
  my $self = shift;
  if (@_) {
    $self->{constraints} = shift;
  };
  return $self->{constraints};
};


sub normalize {
  my $self = shift;

  my ($first, $second);
  unless ($first = $self->{first}->normalize) {
    $self->copy_info_from($self->{first});
    return;
  };

  unless ($second = $self->{second}->normalize) {
    $self->copy_info_from($self->{second});
    return;
  };

  $self->{first} = $first;
  $self->{second} = $second;

  # TODO merge position constraints!
  my @constraints = ();
  my $last = '';
  foreach (@{$self->constraints_in_order}) {

    # Ignore idempotence
    my $c = $_->to_string;
    next if $last eq $c;
    $last = $c;

    # Plan may result in a null-query
    # TODO: Copy warnings etc.
    # Return undef, if the query is 
    my $norm = $_->normalize or next;

    push @constraints, $norm;
  };

  # Set constraints
  $self->constraints(\@constraints);


  # TODO: Reorder subs!

  # TODO: Merge subs


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

  my ($first, $second) = ($self->{first}, $self->{second});

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


sub optimize {
  my ($self, $index) = @_;

  my $first = $self->{first}->optimize($index);
  if ($first->freq == 0) {
    return Krawfish::Query::Nothing->new;
  };

  my $second = $self->{second}->optimize($index);
  if ($second->freq == 0) {
    return Krawfish::Query::Nothing->new;
  };

  my @constraints = ();
  foreach (@{$self->constraints_in_order}) {
    my $opt = $_->optimize($index) or next;
    push @constraints, $opt;
  };

  return Krawfish::Query::Constraints->new(
    \@constraints,
    $first,
    $second
  );
};

sub constraints_in_order {
  my $self = shift;
  my $constr = $self->{constraints};
  return [ sort { $a->to_string cmp $b->to_string } @$constr ];
};



# Plan for index
sub plan_for {
  my ($self, $index) = @_;

  warn 'DEPRECATED';

  my ($first, $second);
  unless ($first = $self->{first}->plan_for($index)) {
    $self->copy_info_from($self->{first});
    return;
  };

  unless ($second = $self->{second}->plan_for($index)) {
    $self->copy_info_from($self->{second});
    return;
  };

  my @constraints = ();
  foreach (@{$self->{constraints}}) {

    # Plan may result in a null-query
    my $plan = $_->plan_for($index) or next;
    push @constraints, $plan;
  };

  return Krawfish::Query::Constraints->new(
    \@constraints,
    $first,
    $second
  );
};


sub filter_by {
  my $self = shift;
  my $corpus_query = shift;
  $self->{first}->filter_by($corpus_query);
  $self->{second}->filter_by($corpus_query);

  # TODO:
  #   filter constraints

  return $self;
};


# TODO: Made helpers constrained knowing

sub maybe_unsorded {
  ...
};


sub to_string {
  my $self = shift;
  my $str = 'constr(';
  $str .= join(',', map { $_->to_string } @{$self->{constraints}});
  $str .= ':';
  $str .= $self->{first}->to_string . ',' . $self->{second}->to_string;
  return $str . ')';
};


1;
