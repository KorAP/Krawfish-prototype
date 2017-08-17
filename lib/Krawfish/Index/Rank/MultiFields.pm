package Krawfish::Index::Rank::MultiFields;
use parent 'Krawfish::Index::Rank';
use strict;
use warnings;

# TODO!

# Fields with multiple values need to create
# two ranking vectors: a forward rank and a
# backward rank.
#
# The forward ranking takes all lexicographically
# smallest values into account (and ignores the rest),
# while the backward ranking takes the lexicographically
# greatest value into account and ignores the rest.

1;
