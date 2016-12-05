package Krawfish::Koral::Result;
use strict;
use warnings;

1;

__END__

sub add_match {
  my ($self, $posting, $index) = @_;

  my $match = Krawfish::Koral::Result::Match->new($posting);

  my $meta = $self->meta;
  if ($meta->fields) {
    $match->fields(
      $index->get_fields($posting->doc_id, $meta->fields)
    );
  };

  # Expand match to, e.g., <base/s=s>
  if ($meta->expansion) {
    my ($start, $end) = $index->get_context(
      $posting,
      $meta->expansion
    );
  };

  # Expand context to, e.g., <base/s=p>
  if ($meta->context) {
    my ($start) = $index->get_context();
  };

  if ($meta->snippet) {
    $self->get_snippet(
      posting => $posting,
      highlights => $meta->highlights,
      snippet_context => $meta->context,
      match_context => $meta->expansion,
      annotations => $match->annotations
    );
  };
};
