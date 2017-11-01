package Krawfish::Posting::List;
use Role::Tiny;
with 'Krawfish::Posting::Bundle';
use warnings;
use strict;

# This is a sorted bundle of postings.

sub matches {
  return $_[0]->size;
};

1;
