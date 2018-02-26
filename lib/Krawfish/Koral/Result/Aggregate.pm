package Krawfish::Koral::Result::Aggregate;
use strict;
use warnings;
use Role::Tiny;

# TODO: Identical to Result::Group

# TODO:
#   This should probably be abstract in the sense,
#   that all aggregation method should
#   make use of the same "flags" storing mechanism
#   and should reuse the pattern mechanism for groups.

requires qw/key
            merge
            inflate
            to_string
            to_koral_fragment/;

# Finish the calculation
sub on_finish {
  $_[0]
};


1;
