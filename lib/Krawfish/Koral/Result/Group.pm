package Krawfish::Koral::Result::Group;
use strict;
use warnings;

# This will be returned by a Group search
# It needs a to_hash method,
# does not require start, end etc ...

# TODO:
#   This is quite similar to K::P::Bundle

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
