package Krawfish::Index::Tokens;
use Krawfish::Log;
use strict;
use warnings;

# See Krawfish::Index::Subtokens

# There is one token list per tokenization

# The Tokens list has the following jobs:
#
# * Check if the number of tokens between two subtokens is
#   in a certain range
#   API: ->count($doc_id, $pos, $length, $min, $max)
#   May as well be extensible for queries like
#   a []{2,7} b
#
# * Add tokens to both sides for extension queries
#   API: ->extend_to_left($doc_id, $pos, $min, $max)
#   API: ->extend_to_right($doc_id, $pos, $min, $max)
#
# * Get the number of tokens per doc_id
#   API: ->count($doc_id)
#        or ->freq($doc_id)
#
# This is a special PostingsList to store the length of tokens
# in subtokens. It may also be used for extensions and distances
# with tokens (instead of subtokens)
# Structure may be: ([docid-delta]([seg-pos-delta][length-varbit])*)*
# The problem is, this won't make it possible to go back and forth.
#

# Get an array of start positions that are in the range of min/max
# Start with the lowest
sub extend_to_left {
  my ($self, $start, $min, $max) = @_;
  # Returns an array of start positions
  ...
};

# Get an array of end positions that are in the range of min/max
# Start with the lowest
sub extend_to_right {
  my ($self, $end, $min, $max) = @_;
  # Returns an array of end positions
  ...
};

# Check if the number of tokens between end and start
# is in the given range.
#
# This is necessary for token distance
# a []{2,3} b
sub count {
  my ($self, $end, $start, $min, $max) = @_;

  # First check if this is even possible based on segments
  # then check on tokens
  ...
}

