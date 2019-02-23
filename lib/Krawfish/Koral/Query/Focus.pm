package Krawfish::Koral::Query::Focus;
use strict;
use warnings;
use List::Util qw'uniq';
use Role::Tiny::With;
use Krawfish::Query::Base::Sorted;
use Krawfish::Koral::Query::Nowhere;
use Memoize;
memoize('min_span');
memoize('max_span');

with 'Krawfish::Koral::Query';

# TODO:
#   If span is maybe_unsorted, use a sorted focus,
#   otherwise an unsorted focus.

# See https://github.com/KorAP/Krill/issues/7
# See https://github.com/KorAP/Krill/issues/48

sub new {
  my $class = shift;
  bless {
    operands => [shift],
    nrs => shift
  }, $class;
};

# Type is focus
sub type { 'focus' };

# List of classes to focus on
sub nrs {
  $_[0]->{nrs};
};

# Normalize the focus query
sub normalize {
  my $self = shift;

  # Remove nested focusses!
  while ($self->operand->type eq 'focus') {
    $self->operand($self->operand->operand);
  };

  my $span;
  # Normalize the span
  unless ($span = $self->operand->normalize) {
    $self->move_info_from($self->operand);
    return;
  };

  # The span matches nowhere
  if ($span->is_nowhere) {

    # Return new nowhere operand
    return Krawfish::Koral::Query::Nowhere->new;
  };

  # Check if the classes require for the focus exist
  my @real_nrs = ();
  foreach my $required (@{$self->nrs}) {
    foreach my $exist ( uniq @{$span->defined_classes}) {
      if ($required == $exist) {
        push @real_nrs, $required;
        last;
      };
    };
  };

  # No existing classes found
  unless (@real_nrs) {

    # Return new nowhere operand
    return Krawfish::Koral::Query::Nowhere->new;
  };

  # All classes of the focus are direct subqueries
  my @real_nrs_2 = @real_nrs;
  my $op = $self->operand;
  while ($op->type eq 'class') {
    for (my $i = 0; $i < @real_nrs_2; $i++) {
      if ($op->number == $real_nrs_2[$i]) {
        splice @real_nrs_2, $i;
      };
    };
    $op = $op->operand;
  };

  # Return the span only
  unless (@real_nrs_2) {

    # Return the span
    return $span;
  };

  # Set real classes that exist
  $self->{nrs} = \@real_nrs;
  return $self
};


# The classes used by the query
sub uses_classes {
  return [
    @{$_[0]->operand->uses_classes},
    @{$_[0]->{nrs}}
  ];
};

# Optimize query to potentially need sorting
sub optimize {
  my ($self, $segment) = @_;

  my $span;

  # Not plannable
  unless ($span = $self->operand->optimize($segment)) {
    $self->copy_info_from($self->span);
    return;
  };

  # Span has no match
  if ($span->max_freq == 0) {
    return $self->builder->nowhere;
  };

  $span = Krawfish::Query::Focus->new($span, $self->nrs);

  # Does not require sorted buffering
  return $span unless $self->operand->maybe_unsorted;

  # Requires sorted buffering
  return Krawfish::Query::Base::Sorted->new($span, 1000);
};

sub min_span {
  # TODO:
  #   Find the nested operands and calculate the span length,
  #   though this may not be trivial
  0
};

sub max_span {
  # TODO:
  #   Find the nested operands and calculate the span length,
  #   though this may not be trivial
  -1
};

sub from_koral {
  ...
};

sub to_koral_fragment {
  ...
};

sub to_string {
  my $self = shift;
  my $str = 'focus(';
  $str .= join ',', @{$self->{nrs}};
  $str .= ':';
  $str .= $self->operand->to_string;
  return $str . ')';

};

1;
