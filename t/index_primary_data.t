use Test::More;
use strict;
use warnings;

use_ok('Krawfish::Index::PrimaryData');

ok(my $pd = Krawfish::Index::PrimaryData->new, 'Create new primary data access');

ok($pd->store(1, 'Das funktioniert sehr gut!'), 'Store primary data');
is($pd->get(1, 4, 16), 'funktioniert', 'Get primary data');

ok($pd->store(2, 'Ein simples Prinzip'), 'Store primary data');
is($pd->get(2, 0, 3), 'Ein', 'Get primary data');
is($pd->get(1, 0, 3), 'Das', 'Get primary data');

ok($pd->store(1, 'Ein simples Prinzip'), 'Store primary data');
is($pd->get(1, 0, 3), 'Ein', 'Get primary data');

done_testing;
