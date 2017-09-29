package Krawfish::Posting::DocBundle;
use parent 'Krawfish::Posting::Bundle';
use warnings;
use strict;

sub matches {
  return scalar @{$_[0]};
};

1;
