use Test::More;
use strict;
use warnings;

use_ok('Krawfish::Index::Store::Dynamic::Dictionary');
use_ok('Krawfish::Index::Store::V1::Dictionary');

ok(my $tst = Krawfish::Index::Store::Dynamic::Dictionary->new, 'Construct new tst');

ok($tst->insert('abc', 1), 'Insertion');
ok($tst->insert('abb', 2), 'Insertion');
ok($tst->insert('ab', 3), 'Insertion');
ok($tst->insert('bc', 4), 'Insertion');

is($tst->search('ab'), 3, 'ab is part of the TST');
is($tst->search('abb'), 2, 'abb is part of the TST');
is($tst->search('abc'), 1, 'abc is part of the TST');
is($tst->search('bc'), 4, 'ab is part of the TST');

is(Krawfish::Index::Store::V1::Dictionary::_complete_middle(10), 7, 'Find the complete middle of a length');
is_deeply(Krawfish::Index::Store::V1::Dictionary::_complete_order(10), [7,4,9,2,6,8,10,1,3,5], 'Find a length order');



#print join(',', $tst->store),"\n";

ok(my $complete = Krawfish::Index::Store::V1::Dictionary->from_dynamic($tst),
   'Construct new complete tst');

ok(!$complete->search('a'), 'a is not part of the TST');
ok(!$complete->search('ba'), 'a is not part of the TST');
is($complete->search('ab'), 3, 'ab is part of the TST');
is($complete->search('abb'), 2, 'abb is part of the TST');
is($complete->search('abc'), 1, 'abc is part of the TST');
is($complete->search('bc'), 4, 'ab is part of the TST');

#diag $complete->to_string(11);
#is($complete->term_by_term_id(4), '', 'Term by term id');

done_testing;
