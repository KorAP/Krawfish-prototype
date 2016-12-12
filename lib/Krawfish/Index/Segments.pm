package Krawfish::Index::Segments;
use strict;
use warnings;

# Store offsets for direct access using doc id and pos

# TODO:
#   This may be implemented using a postings list, but inside positions,
#   it should be possible to move backwards as well.
#   The segments structure may be augmented with a skiplist
#   and be a highly optimized position encoding, because character offsets
#   should normally have values between 0 and 16.


# Constructor
sub new {
  my $class = shift;
  bless {
    file => shift
  }, $class;
};

# TODO: Better store length ...
# Store offsets
sub store {
  my $self = shift;

  # Get data to store per segment
  my ($doc_id, $segment, $start_char, $end_char) = @_;

  # Store all segments
  $self->{$doc_id . '#' . $segment} = [$start_char, $end_char];
  return $self;
};


# Get offsets
# TODO: Support caching!
sub get {
  my $self = shift;
  my ($doc_id, $segment) = @_;
  return $self->{$doc_id . '#' . $segment};
};

1;
