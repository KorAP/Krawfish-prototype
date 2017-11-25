package Krawfish::Posting::List;
use Role::Tiny::With;
use warnings;
use strict;

with 'Krawfish::Posting::Bundle';

# This is a sorted bundle of postings.

sub match_count {
  return $_[0]->size;
};

1;
