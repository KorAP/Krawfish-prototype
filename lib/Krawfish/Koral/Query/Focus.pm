package Krawfish::Koral::Query::Focus;
use parent 'Krawfish::Koral::Query';
use Krawfish::Query::Base::Sorted;
use strict;
use warnings;

sub new {
  my $class = shift;
  bless {
    span => shift,
    nrs => shift
  }, $class;
};

sub span {
  $_[0]->{span};
};

sub nrs {
  $_[0]->{nrs};
};

# If span is maybe_unsorted, use a sorted focus, otherwise an unsorted focus.

sub plan_for {
  my ($self, $index) = @_;

  my $span;

  # Not plannable
  unless ($span = $self->span->plan_for($index)) {
    $self->copy_info_from($self->span);
    return;
  };

  # Span has no match
  if ($span->freq == 0) {
    return $self->builder->nothing;
  };

  $span = Krawfish::Query::Focus->new($span, $self->nrs);

  # Does not require sorted buffering
  return $span unless $self->span->maybe_unsorted;

  # Requires sorted buffering
  return Krawfish::Query::Base::Sorted->new($span, 1000);
};

1;
