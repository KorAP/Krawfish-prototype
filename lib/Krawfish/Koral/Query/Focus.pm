package Krawfish::Koral::Query::Focus;
use strict;
use warnings;
use Role::Tiny::With;
use Krawfish::Query::Base::Sorted;
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


sub type { 'focus' };

sub nrs {
  $_[0]->{nrs};
};


sub normalize {
  # TODO:
  return $_[0];
};

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
