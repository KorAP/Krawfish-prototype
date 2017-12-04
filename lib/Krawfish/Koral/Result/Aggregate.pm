package Krawfish::Koral::Result::Aggregate;
use strict;
use warnings;
use Role::Tiny;

requires qw/key merge/;

# Finish the calculation
sub on_finish {
  $_[0]
};


1;
