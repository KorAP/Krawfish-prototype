package Krawfish::Posting::Sorted;
use parent 'Krawfish::Posting';
use strict;
use warnings;

# Sorted may be bundled!
# Probably use K::P::Bundle instead!

# This posting iterator is returned by the HeapSort system.

sub doc_id {
  ...
};

sub matches {
  ...
};

sub rank {
  ...
};

sub same {
  ...
};

1;
