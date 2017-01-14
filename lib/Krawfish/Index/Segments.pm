package Krawfish::Index::Segments;
use Krawfish::Log;
use strict;
use warnings;

# Store offsets for direct access using doc id and pos
# - in addition store term ids and characters for presorting

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
#
#   In addition, the term_id needs to be stored!

# TODO: Term-IDs may be better stored in a separate file, to keep the file small.

use constant DEBUG => 0;

# Constructor
sub new {
  my $class = shift;
  bless {
    file => shift,

    # Define, how many start characters will be stored
    start_char_length => shift // 2,

    # Define, how many start characters will be stored
    end_char_length => shift // 2
  }, $class;
};

# TODO: Better store length ...
# Store offsets
sub store {
  my $self = shift;

  # Get data to store per segment
  my ($doc_id, $segment, $start_char, $end_char, $term_id, $term) = @_;

  if ($term) {
    # Get the first and last characters of the term
    my ($first, $last) = (substr($term, 0, 2), scalar reverse substr($term, -2));

    # Store all segments
    $self->{$doc_id . '#' . $segment} = [$start_char, $end_char, $term_id, $first, $last];

    if (DEBUG) {
      print_log('segments', "Store segment at [$doc_id,$segment]");
      print_log('segments', '  with ' . join(','),@{$self->{$doc_id . '#' . $segment}});
    };
  }

  # Temporary
  else {
    # Store all segments
    $self->{$doc_id . '#' . $segment} = [$start_char, $end_char];
  }

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
