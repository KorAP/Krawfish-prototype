package Krawfish::Index::Tokens;
use Krawfish::Log;
use strict;
use warnings;

# There is one token list per tokenization

# The Token list has the following jobs:
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
#   API: ->freq_in_doc($doc_id)
#   (Necessary for Result::Aggregate::TokenFreq)
#
# * Get the maximum number of subtokens a token
#   of this foundry can have
#   (necessary for Constraint::InBetween)
#   ->max_subtokens;

# TODO:
#   A possible structure would be (without including skip data)
#   ([doc-id][freq-varint]([pos-delta][length-varint])*)
#   where only start positions are stored for lengths > 1.
#   Skip data should be included only for every ~128 entries
#   and each skip-block should have a previous pointer
#   to make skipping back possible.


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
};

# Returns the number of tokens per foundry
sub freq_in_doc {
  ...
};

sub max_subtokens {
  ...
};

sub skip_doc {

};

1;

