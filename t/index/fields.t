use Test::More;
use strict;
use warnings;
use utf8;

use_ok('Krawfish::Index::Fields');

# Test ranking
my ($max_rank, $ranked) = Krawfish::Index::Fields::rank_str(
  [qw/Frank Paul Frank Abraham Michael Frank Bill/]
);
is($max_rank, 5, 'Rank');
is_deeply($ranked, [3, 5, 3, 1, 4, 3, 2], 'Rank');


# Test ranking
($max_rank, $ranked) = Krawfish::Index::Fields::rank_str(
  [qw/eins zwei drei vier fünf sechs sieben acht neun zehn/]
);
is($max_rank, 10, 'Rank');
is_deeply($ranked, [3, 10, 2, 8, 4, 6, 7, 1, 5, 9], 'Rank');

done_testing;
