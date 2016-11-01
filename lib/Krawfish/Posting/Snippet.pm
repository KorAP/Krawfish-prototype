package Krawfish::Posting::Snippet;
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
    $self->doc_id,
    $self->start
  );

  my $end_segment = $offsets->get(
    $self->doc_id,
    $self->end
  );

  return $self->index->primary->get(
    $self->doc_id,
    $start_segment,
    $end_segment
  );
};

1;
