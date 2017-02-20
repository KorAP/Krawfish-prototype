package Krawfish::Index::Subtokens;
use Krawfish::Log;
use strict;
use warnings;

# See Krawfish::Index::Tokens

# There is only one subtoken list for the documents

# The Subtokens list (not different for different tokenizations)
# has the following job:
#
# * Return forward index offsets for a certain subtoken
#   (for the current forward index implementation, only the
#    start offset is necessary)
#   API: ->get_offset($doc_id, $pos)
#
# * Get the term_id at a certain position
#   API: ->get_term_id($doc_id, $pos)
#
#   IDEA: This will get the offset and look into the forward index
#         for the $term_id. Or it will directly store the $term_id
#         in the stream.
#
# * Get the surface form from the dictionary as fast as possible
#   This will first find the $term_ids in the forward index and resolve them
#   (potentially).
#   API: ->get_surface($doc_id, $pos)
#        ->get_surface($doc_id, $pos, $length)
#
# * Get the prefix and suffix rank of the surface form for fast
#   sorting. All terms should be preranked in prefix and suffix order
#   for the standard collation.
#   API: ->get_prefix_rank($doc_id, $pos)
#        ->get_suffix_rank($doc_id, $pos)
#
#   IDEA:  It would be nice to have the ranks being stored in the dictionary
#          to avoid redundancy. So this would be implemented as first
#          looking up the $term_id in the forward_index, then retrieving
#          the rank based on the $term_id in the dictionary.
#          As these sorting parts of the dictionary are not necessary all the time,
#          they may not need to reside in memory all the time.
#
#   REQUIREMENT: For on-the-fly sorting it may be beneficial to have a fast
#                incremental ->next() and ->skip_to() like method.
#                For finding the offset for a match, a get() should
#                be allowed to be slow.
#                A good argument for fast on-the-fly-sorting is also
#                grouping, which needs fast access to the term_ids, so
#                they may need to be stored redundantly
#
#   DATASTRUCTURE: [doc_id]([delta_varint_offset][term_id_varint])*
#                  Augmented with a SkipList.
#
# TODO:
#   This may be implemented using a postings list, but inside positions,
#   it should be possible to move backwards as well.
#   The tokens structure may be augmented with a skiplist
#   and be a highly optimized position encoding.
#
#   It should also contain information about the first two characters
#   of a term and possibly the last two characters, necessary to bucket sort terms.
#   The characters are stored as UTF-8 or similar -
#   it may be beneficial to have the most common characters need the least
#   bits.
#   Note that this information needs to store characters and not
#   bytes, as bytes may not be helpful for sorting!
#   This may as well use a prefix_rank and a suffix_rank for bucket-sorting.
#
#   In addition, the surface term_id needs to be accessible fastly!
#   TODO: Term-IDs may be better stored in a separate file, to keep the file small.


use constant DEBUG => 1;

# Constructor
sub new {
  my $class = shift;
  bless {
    file => shift,

    # Define, how many start characters will be stored
    # This is useful for alphabetic sorting
    # start_char_length => shift // 2,

    # Define, how many start characters will be stored
    # This is useful for alphabetic sorting
    # end_char_length => shift // 2,

    array => [],
    pos => -1,
  }, $class;
};

# TODO: Better store length ...
# Store offsets
sub store {
  my $self = shift;

  # Get data to store per segment
  my ($doc_id, $subtoken, $start_char, $end_char, $subterm_id, $subterm) = @_;

  # TODO: THIS IS PROBABLY NOT NECESSARY!
  if ($subterm) {
    # Get the first and last characters of the term
    my ($first, $last) = (substr($subterm, 0, 2), scalar reverse substr($subterm, -2));

    # Store all segments
    $self->{$doc_id . '#' . $subtoken} = [$start_char, $end_char, $subterm_id, $first, $last];

    if (DEBUG) {
      print_log('segments', "Store subtoken at [$doc_id,$subtoken]");
      print_log('segments', '  with ' . join(','),@{$self->{$doc_id . '#' . $subtoken}});
    };
  }

  # Temporary
  else {
    # Store all segments
    $self->{$doc_id . '#' . $subtoken} = [$start_char, $end_char];
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
  if (DEBUG) {
    print_log('toklist', "Appended $token with $doc_id, $pos" . ($end ? "-$end" : ''));
  };
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
