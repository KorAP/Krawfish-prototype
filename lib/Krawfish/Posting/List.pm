package Krawfish::Posting::List;
use Role::Tiny::With;
use warnings;
use strict;

with 'Krawfish::Posting::Bundle';

# This is a sorted bundle of postings.

sub matches {
  return $_[0]->size;
};

1;
