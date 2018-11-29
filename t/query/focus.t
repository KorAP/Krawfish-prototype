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
