use Test::More skip_all => 'Not yet implemented';
use Test::Krawfish;
use strict;
use warnings;

# Doc <a1>[a]<a2>[b1][b2]</a1>[c]</a2>
# focus(within(<a>, {[b]})) requires sorting of results
# <a1>..[b1]...</a1> -> [b1]
# <a2>..[b1]...</a2> -> [b1]
# <a1>..[b2]...</a1> -> [b2]
# <a2>..[b2]...</a2> -> [b2]
#
# The focus query needs to implement a priority queue
# as discussed in https://github.com/KorAP/Krill/issues/7#issuecomment-444459046
# to buffer unsorted results and return sorted classes, whenever
# the wrapping query moves forward.
