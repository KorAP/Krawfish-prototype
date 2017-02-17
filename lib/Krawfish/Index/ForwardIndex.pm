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
# TODO:
#   This is great for retrieving pagebreaks, annotations, primary data,
#   perhaps help on regex ...
#   But can this help to expand the context of a match to a certain element context?
#   Probably by retrieving the data with a certain maximum offset (say left 100 subtokens, right 100 subtokens)
#   and first check for the expanding element start on the left, then move to the right.
#
# TODO:
#   In case the term IDs are retrieved for surface sorting,
#   it may be useful to not have much data in memory.
#   Look into K::I::Subtokens for use of $term_ids there. It may not be crucial though.

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

sub get_expanded {
  ...
};


# Return a stream of elements (primary text and annotations)
sub get_annotated {
  my $self = shift;
  my ($doc_id, $offset, $length, $foundry, $layer) = @_;
  ...
};

# Return a stream of elements (primary text and annotations)
# that is within a certain element
sub get_annotated_expanded {
  my $self = shift;
  my ($doc_id, $offset, $length, $foundry, $max_exp, $layer, $element) = @_;
  ...
};


# Return the surface string only
# This should be as fast as possible, as it is used for aggregations
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
