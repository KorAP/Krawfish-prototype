package Krawfish::Index::Rank::SubTerms;
use parent 'Krawfish::Index::Rank';
use strict;
use warnings;

warn 'DEPRECATED';

# While FieldsRank is defined per Segment,
# TermRank is defined per Dictionary.
# That means per node there are two Term-Ranks
# per direction (prefix and suffix):
# One static and one dynamic.
#
# TODO:
#   should have a similar API as FieldsRank!

# TODO:
#   There are two possible rank value types:
# 1 VALUE IS EVEN: The global rank from
#   the static dictionary
# 2 VALUE IS ODD: The prerank, means,
#   it is sorted based on the rank and takes the place
#   between the two rank values, but it may occurr
#   multiple types for different values.
#   This comes from the dynamic dictionary.

1;
