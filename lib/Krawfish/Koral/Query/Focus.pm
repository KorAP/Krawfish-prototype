package Krawfish::Koral::Query::Focus;
use parent 'Krawfish::Koral::Query';
use Krawfish::Query::Base::Sorted;
use strict;
use warnings;
use Memoize;
memoize('min_span');
memoize('max_span');

# TODO:
#   If span is maybe_unsorted, use a sorted focus,
#   otherwise an unsorted focus.


sub new {
  my $class = shift;
  bless {
    operands => [shift],
    nrs => shift
  }, $class;
};

sub nrs {
  $_[0]->{nrs};
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
    return $self->builder->nothing;
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

1;
