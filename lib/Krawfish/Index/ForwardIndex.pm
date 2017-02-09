package Krawfish::Index::ForwardIndex;
use strict;
use warnings;

# This represents a forward index of the data,
# accessible by document ID and byte offset.
#
# In the end this should replace the primary data.
#
# TODO:
#   On merge, first make a termID->termID-mapping based on the dictionary
#   merge. Then, convert the forward index based on this table without
#   dictionary lookup.
#
sub new {
  my $class = shift;
  bless {
    file => shift,
    forward => []
  }, $class;
};

sub store {
  my $self = shift;
  my ($doc_id, $text) = @_;
  $self->{forward}->[$doc_id] = $text;
};

sub get {
  my $self = shift;
  my ($doc_id, $offset, $end) = @_;
  return substr($self->{forward}->[$doc_id], $offset, $end - $offset);
};


# Return a stream of elements (primary text and annotations)
sub get_annotated {
  my $self = shift;
  my ($doc_id, $offset, $length, $foundry, $layer) = @_;
  ...
};

# Return the surface string only
sub get_surface {
  my ($self, $doc_id, $offset, $length) = @_;
  ...
};

# Add the document as an annotated stream
sub add_stream {
  my $self = shift;
  my ($doc_id, $stream) = @_;
  ...
};

1;
