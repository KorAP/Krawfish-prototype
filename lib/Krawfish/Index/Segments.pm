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
#
#   It should also contain information about the first two characters
#   of a term and possibly the last two characters, necessary to bucket sort terms.
#   The characters are stored as UTF-8 or similar -
#   it may be beneficial to have the most common characters need the least
#   bits.
#   Note that this information needs to store characters and not
#   bytes, as bytes may not be helpful for sorting!

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


# Define, how many start characters will be stored
sub start_char_length {
  2;
}

# Define, how many start characters will be stored
sub end_char_length {
  2;
}

# TODO: A Segment has ->start_offset, ->length, ->first_chars, ->last_chars, ->term_id
# term_id may either be a term-id or a string

1;
