package Krawfish::Posting::Match;
use parent 'Krawfish::Posting';
use strict;
use warnings;

sub index {
  shift->{index} = shift;
};

sub to_snippet {
  my $self = shift;

  my $offsets = $self->index->offsets;
  my $start_segment = $offsets->get(
    $self->doc,
    $self->start
  );

  my $end_segment = $offsets->get(
    $self->doc,
    $self->end
  );

  return $self->index->primary->get(
    $self->doc,
    $start_segment,
    $end_segment
  );
};

1;
