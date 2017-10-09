package Krawfish::Koral::Result::Group;
use strict;
use warnings;

# This will be returned by a Group search
# It needs a to_hash method,
# does not require start, end etc ...

# TODO:
#   This is quite similar to K::P::Bundle

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


sub freq {
  ...
};

sub doc_freq {
  ...
};

sub to_hash {
  ...
};

1;
