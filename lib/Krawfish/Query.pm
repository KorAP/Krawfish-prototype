package Krawfish::Query;
use strict;
use warnings;

# Current span object
sub current {
  my $self = shift;
  return unless defined $self->{doc_id};
  return Krawfish::Posting->new(
    doc_id  => $self->{doc_id},
    start   => $self->{start},
    end     => $self->{end},
    payload => $self->{payload}
  );
};

# Overwrite
# TODO: Accepts a target doc
# TODO: Returns the doc_id of the current posting
sub next;

# Forward to next start position
sub next_greater_start;



sub skip_doc {
  my $self = shift;
  my $doc_id = shift;
  while ($self->{doc_id} && $self->{doc_id} < $doc_id) {
    $self->next;
  };
  return $self->{doc_id};
};

# In Lucene it's exemplified:
# int advance(int target) {
#   int doc;
#   while ((doc = nextDoc()) < target) {
#   }
#   return doc;
# }

sub freq {
  -1;
};

# Overwrite
sub to_string {
  ...
};

1;
