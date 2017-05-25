package Krawfish::Index::Store::V1::Tokens;
use strict;
use warnings;

# This is a special PostingsList to store the length of tokens
# in subtokens. It may also be used for extensions and distances
# with tokens (instead of subtokens)
#
# Structure may be: ([docid-delta]([seg-pos-delta][length-varbit])*)*
# The problem is, this won't make it possible to go back and forth.
#

# Structure could be:
# Probably with a SkipList!
# ([docid:delta-int][max-token-length:varint]
#   ([seg-pos:delta-int][length:uniint])*
# )*
#
# The difference will only be stored, if it is > 1 (so if a token is greater
# than one subtoken).

sub new {
  my ($class, $file, $foundry) = @_;
  bless {
    file => $file,
    foundry => $foundry,
    doc_id => -1
  }, $class;
};


# Return the tokenization foundry
sub foundry {
  $_[0]->{foundry};
};


# Return the current doc_id
sub doc_id {
  $_[0]->{doc_id};
};


# Return the maximum number of subtokens a token
# can reach in this document
sub max_token_length {
  $_[0]->{max_token_length}
};

# Check if the number of tokens between end and start
# is in the given range.
#
# This is necessary for token distance
# a []{2,3} b
sub count {
  my ($self, $doc_id, $start, $end) = @_;

  # Return the number of tokens in-between
  # This should probably return a special flag, if the start position
  # is in the middle of a token or the end-position is
  # in the middle of a token
  ...
};

# Get an array of start positions that are in the range of min/max
# Start with the lowest
sub extend_to_left {
  my ($self, $doc_id, $start, $min, $max) = @_;
  # This needs to move first to $start - ($max * $self->max_token_length)
  # and then collect tokens.
  # It needs to forget tokens that will, in the end, exceed $max
  ...
};

# Get an array of end positions that are in the range of min/max
# Start with the lowest
sub extend_to_right {
  my ($self, $doc_id, $end, $min, $max) = @_;
  ...
};


1;
