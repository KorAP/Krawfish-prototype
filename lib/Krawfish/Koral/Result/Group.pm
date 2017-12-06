package Krawfish::Koral::Result::Group;
use Role::Tiny;
use strict;
use warnings;

# TODO: Identical to Result::Aggregate

requires qw/key
            merge
            inflate
            to_string
            to_koral_fragment/;

# This will be returned by a Group search
# It needs a to_hash method,
# does not require start, end etc ...

# With a witness, the group has:
# {
#   criterion => [freq, doc_freq, match]
# }
# The match can be anything - so it may even be a first example snippet.
#
# But with a multiple class() corpora, there may be more:
#
# {
#   criterion => [freq, doc_freq, freq, doc_freq, freq, doc_freq, ...]
# }
#
# or even
#
# {
#   criterion => [freq, doc_freq, match, freq, doc_freq, match, freq, doc_freq, match ...]
# }

sub on_finish {
  $_[0];
};

1;

