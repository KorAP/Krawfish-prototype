package Krawfish::Koral::Query::Constraints;
use parent 'Krawfish::Koral::Query';
use List::Util qw/min max/;
use Krawfish::Query::Constraints;
use Krawfish::Query::Constraint::Position;
use Krawfish::Util::Bits;
use Krawfish::Log;
use v5.10;
use strict;
use warnings;
use Memoize;
memoize('min_span');
memoize('max_span');

use constant DEBUG => 1;

# TODO:
#   Normalization phase can be optimized.
#
#     pos=precedesDirectly,precedes;between=1-4 -> pos=precedes;between=1-4
#     pos=precedesDirectly,precedes;between=0 -> pos=precedesDirectly
#     ...

our %CONSTR_ORDER = (
  constr_pos   => 1,
  constr_dist  => 2,
  constr_not   => 3,
  constr_class => 5
);

# Constructor
sub new {
  my $class = shift;
  bless {
    constraints => shift,
    operands => [@_]
  }, $class;
};


# Query type
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

  print_log('kq_constr', 'Normalize operands') if DEBUG;

  # Normalize both operands
  my ($first, $second);
  unless ($first = $self->{operands}->[0]->normalize) {
    $self->copy_info_from($self->{operands}->[0]);
    return;
  };

  print_log('kq_constr', 'First operand is ' . $first->to_string) if DEBUG;

  unless ($second = $self->{operands}->[1]->normalize) {
    $self->copy_info_from($self->{operands}->[1]);
    return;
  };

  print_log('kq_constr', 'Second operand is ' . $second->to_string) if DEBUG;

  # One operand is not existing
  if ($first->is_nothing || $second->is_nothing) {

    # Return new nothing operand
    return Krawfish::Koral::Query::Nothing->new;
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
    # TODO:
    #   Make this normalize_c and return an array!
    my @norm = $_->normalize or next;

    push @constraints, @norm;
  };

  # No constraints defined
  if (@constraints == 0) {
    $self->error(000, 'Constraint query without a valid constraint');
    return;
  };


  # Order constraints
  @constraints = sort { $CONSTR_ORDER{$a->type} <=> $CONSTR_ORDER{$b->type} } @constraints;

  # TODO:
  #   Simplify multiple constraints!

  # Check consecutive queries
  for (my $i = 0; $i < @constraints - 1;) {

    my $first = $constraints[$i];
    my $second = $constraints[$i+1];

    # Both constraints have the same type
    if ($first->type eq $second->type) {

      # Merge positional constraints
      if ($first->type eq 'constr_pos') {

        # Join frames
        $first->frames($first->frames & $second->frames);

        # Remove not used positional constraint
        splice(@constraints, $i+1, 1);
        next;
      }

      # Join distances
      elsif ($first->type eq 'constr_dist') {

        # WARNING:
        #   This only works as long as token bases are not supported!

        # Set new minimum value
        if (!defined $first->min || (defined $second->min && ($first->min < $second->min))) {
          $first->min($second->min);
        };

        # set new maxium value
        if (!defined $first->max || (defined $second->max && ($first->max > $second->max))) {
          $first->max($second->max);
        };

        # New distance contradicts itself
        if (defined $first->min && defined $first->max && $first->min > $first->max) {
          return $self->builder->nothing;
        };

        # Remove not used distance constraint
        splice(@constraints, $i+1, 1);
        next;
      };
    };

    $i++;
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

  # Normalization may result in no valid query
  return unless $self;


  #   Using min_span and max_span it can be checked,
  #   if a position constraint like overlap
  #   can be valid or not, for example
  #
  #   $qb->constraints(
  #     [$qb->c_position('overlapsLeft', 'overlapsRight')],
  #     $qb->repeat($qb->term('a'), 2),
  #     $qb->term('b')
  #   )
  #
  #   can never match!
  if ($self->max_span != -1 && $self->min_span > $self->max_span) {
    return $self->builder->nothing;
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


# Optimize the query for an segment
sub optimize {
  my ($self, $segment) = @_;

  # Optimize operands
  my $first = $self->{operands}->[0]->optimize($segment);
  if ($first->max_freq == 0) {
    return Krawfish::Query::Nothing->new;
  };

  my $second = $self->{operands}->[1]->optimize($segment);
  if ($second->max_freq == 0) {
    return Krawfish::Query::Nothing->new;
  };

  # Optimize constraints
  my @constraints = ();
  foreach (@{$self->constraints}) {
    my $opt = $_->optimize($segment) or next;
    push @constraints, $opt;
  };

  # Create constraint
  return Krawfish::Query::Constraints->new(
    \@constraints,
    $first,
    $second
  );
};


# Inflate operands and constraints
sub inflate {
  my ($self, $dict) = @_;

  warn 'DEPRECATED in favor of identify!';

  my $ops = $self->operands;

  # Inflate on all operands
  my $i = 0;
  for (; $i < @$ops; $i++) {
    $ops->[$i] = $ops->[$i]->inflate($dict);

    if ($ops->[$i]->is_nothing) {
      # Return new nothing operand
      return Krawfish::Koral::Query::Nothing->new;
    };
  };

  my $cs = $self->constraints;

  # Inflate all constraints
  for ($i = 0; $i < @$cs; $i++) {
    $cs->[$i] = $cs->[$i]->inflate($dict);
  };

  return $self;
};


# Inflate operands and constraints
sub identify {
  my ($self, $dict) = @_;

  my $ops = $self->operands;

  # Inflate on all operands
  my $i = 0;
  for (; $i < @$ops; $i++) {
    $ops->[$i] = $ops->[$i]->identify($dict);

    if ($ops->[$i]->is_nothing) {
      # Return new nothing operand
      return Krawfish::Koral::Query::Nothing->new;
    };
  };

  my $cs = $self->constraints;

  # Inflate all constraints
  for ($i = 0; $i < @$cs; $i++) {
    $cs->[$i] = $cs->[$i]->identify($dict);
  };

  return $self;
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
  if (@{$self->{constraints}}) {
    $str .= join(',', map { $_->to_string } @{$self->{constraints}});
    $str .= ':';
  };
  $str .= join ',', map { $_->to_string } @{$self->{operands}};
  return $str . ')';
};


# The minimum number of tokens of this span
sub min_span {
  my $self = shift;
  my $first_span = $self->operands->[0]->min_span;
  my $second_span = $self->operands->[1]->min_span;

  # The minimum token length is - when no constraint is set -
  # the overlapping of both operands
  my $min = max($first_span, $second_span);

  # Iterate over constraints
  foreach (@{$self->constraints}) {
    my $c_min = $_->min_span($first_span, $second_span);

    # If the new minimum is greater, adopt the value
    if ($c_min > $min) {
      $min = $c_min;
    };
  };

  # return minimum value
  return $min;
};


# The maximum number of tokens of this span
sub max_span {
  my $self = shift;

  # The maximum token length is - when no constraint is set -
  # arbitrary
  my $max = -1;

  # Refine based on constraints
  if (@{$self->constraints}) {
    my $first_span = $self->operands->[0]->max_span;
    my $second_span = $self->operands->[1]->max_span;

    # Check all constraints
    foreach (@{$self->constraints}) {
      my $c_max = $_->max_span($first_span, $second_span);

      # ignore -1
      next if $c_max == -1;

      # If the new maximum is smaller, adopt the value
      if ($c_max < $max || $max == -1) {
        $max = $c_max;
      };
    };
  };

  # Return maximum value
  $max;
};


1;
