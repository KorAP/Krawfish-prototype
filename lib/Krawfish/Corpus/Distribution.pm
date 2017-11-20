package Krawfish::Corpus::Distribution;
use strict;
use warnings;
use Role::Tiny::With;

with 'Krawfish::Corpus';

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
#   that there may be a lot elements missing, so it may be useful to
#   buffer the query with the lowest freq first and then go through
#   the other one with mild skips.
#
#   However - in case skips are not available,
#   this may be slow ...

# TODO:
#   Support corpus classes

# TODO:
#   Another distribution variant would be
#   distr(doc[1:1]: 'author:Goethe', 'author:Schiller')
#   where both corpora will have an equal size.
#   Unfortunately an equal size does not necessarily
#   mean:
#     - the text size is equivalent
#     - the sampling is reasonably good
#   A solution for the first problem could be to formulate
#   a query like this:
#
#     distr(token[1:1:~10%]: 'author:Goethe', 'author:Schiller')
#
#   that would buffer documents from a and be and check the
#   number of subtokens and always release the buffer, once the
#   tolerance level is reached (remembering the token difference)
#   for the buffer. This can be problematic, in case the
#   tolerance level is never met.
#   It may also be problematic when one author has - in the result
#   only one long document and the other author has only 100
#   short texts.
#
#   To deal with the second problem, another query may be provided
#   as
#
#     sampleDistr([2:1]: 'author:Goethe', 'author:Schiller')
#
#   where both corpora are first created, based on both sizes
#   it is chosen which corpus needs to be reduced to reach the
#   desired ratio, and based on that, the reducible corpus is
#   sampled (by randomly removing items).
#   This will be slow!


1;
