package Krawfish::Index::Subtokens;
use Krawfish::Log;
use strict;
use warnings;

# See Krawfish::Index::Tokens

# The Subtokens list (not different for different tokenizations)
# has the following job:
#
# * Return forward index offsets for a certain subtoken
#   (for the current forward index implementation, only the
#    start offset is necessary)
#   API: ->get($doc_id, $pos)
#
# * Get the surface form from the forward index as fast as possible
#   This will first find the offsets and then collect the term_ids from
#   the forward index and resolve the term_ids (potentially).
#   API: ->get_surface($doc_id, $pos)
#        ->get_surface($doc_id, $pos, $length)
#
# * Get the start and end characters of the surface form for fast
#   sorting. All terms should be preranked in prefix and suffix order
#   for the standard collation.
#   API: ->get_prefix_rank($doc_id, $pos)
#        ->get_suffix_rank($doc_id, $pos)


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

# The following APIs are needed:
# ->get_plus('opennlp', 2,4)
# That is needed to get the subtokens used for
# extensions

# This is a special PostingsList to store the length of tokens
# in segments
#
# It may also be used for extensions and distances with tokens
# (instead of segments)
#
# That's why this postingslist has a special API for extensions
# and word distances.
#
# Structure may be: ([docid-delta]([seg-pos-delta][length-varbit])*)*
#
# The problem is, this won't make it possible to go back and forth.


use constant DEBUG => 0;

# Constructor
sub new {
  my $class = shift;
  bless {
    file => shift,

    # Define, how many start characters will be stored
    # This is useful for alphabetic sorting
    start_char_length => shift // 2,

    # Define, how many start characters will be stored
    # This is useful for alphabetic sorting
    end_char_length => shift // 2,

    array => [],
    pos => -1,
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


sub append {
  my $self = shift;
  my ($token, $doc_id, $pos, $end) = @_;
  print_log('toklist', "Appended $token with $doc_id, $pos" . ($end ? "-$end" : '')) if DEBUG;
  push(@{$self->{array}}, [$doc_id, $pos, $end]);
};

sub next;

sub pos {
  return $_[0]->{pos};
};

sub token {
  return $_[0]->{array}->[$_[0]->pos];
};


sub freq;

sub skip_to_doc;

sub skip_to_pos;




1;
