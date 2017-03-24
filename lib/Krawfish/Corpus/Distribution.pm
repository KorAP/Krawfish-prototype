package Krawfish::Corpus::Distribution;
use strict;
use warnings;

# TODO:
#   distr([1:3], 'author:Goethe', 'author:Schiller')
#
#   Go through both queries and buffer them.
#   Once the first buffer has a position >= 1 and the
#   second query has a position >= 3, release both
#   buffers in document order (aka do an or-query)
#   in the requested ratio.
#
#   In the worst case, this means that one of the
#   queries will be completely buffered, while the other
#   has only a few entries, making most of the buffered elements
#   rendered useless.
#   However - the strategy described above means,
#   that there may be a lot elements missing, so it may be usefull to
#   buffer the query with the lowest freq first and then go through
#   the other one with mild skips.
#
#   However - in case skips are not available,
#   this may be slow ...

1;
