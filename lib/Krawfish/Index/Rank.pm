package Krawfish::Index::Rank;
use strict;
use warnings;

# TODO:
#   Each field, the prefixes for subterms, and the
#   suffixes for subterms have - in addition to the
#   dictionary - a rank-file that does not only
#   store the ranks per doc, but all values
#   in sorted order, respecting a certain collation.
#
#   This file will only be consulted for reranking (merging),
#   so it may be compressed on disk and potentially
#   stored with incremental encoding/front coding

# TODO:
#   Ranking is simple:
#     1. rank all values by sorting them - give them rank numbers.
#   If new values are added:
#     1. Sort all new values separately
#        Start at position i = MAX_RANK/2
#        while there are values in the list:
#        2. Look up, if the smallest value is already present
#           LOOKUP
#           yes -> ignore, keep position as i
#                  but for rank-integration, keep the rank in
#                  a special data strukture like ranked_cache
#           no -> go to 3
#        # HOW TO SEARCH HERE!?
#        3. Get the preceeding and following rank values and
#           define the middle value for the value as a prerank
#           and set position value to 0.
#        4. For all next values to prerank, look, if they have the same
#           surrounding ranks (just check, if the greater ranked value is also greater
#           as the current value).
#           yes ->
#             Check, if the value is identical
#             yes -> add known prerank and same position value, go to 2
#             no -> add known prerank and an incremented position value, go to 2
#           no -> go to 2
#   For merging, just go linearly through all
#   Ranks in a merge sort way. Whenever there is a value that needs to be integrated
#   from the prerank list, increment all values.
#   HOW:
#     The ranked list will be iterated in document order
#     The precached_rank needs to have a special data structure with an API:
#     ->update_rank(rank), that will take a rank of the ranked list
#     and returns the rank incremented by the number of preranks before this rank.
#     in case, no rank was inserted before, this will be the same.
#     Then, all new documents with preranked or ranked but not integrated yet
#     values will be appended to the rank stream.
#
# TODO:
#   Use something like that:
#   http://pempek.net/articles/2013/08/03/bit-packing-with-packedarray/
#   https://github.com/gpakosz/PackedArray
#
# TODO:
#   $max_rank is important, because it indicates
#   how many bits per doc are necessary to encode
#   the rank!
#
# TODO:
#   In case, a field is only set for a couple of documents, a different
#   strategy may be valid.

sub max {
  $_[0]->{max};
};


# Needs to be implemented
# in the child modules
sub merge {
  ...
};

1;
