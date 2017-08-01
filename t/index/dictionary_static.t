use Test::More;
use strict;
use warnings;

use_ok('Krawfish::Index::Store::Dynamic::Dictionary');
use_ok('Krawfish::Index::Store::V1::Dictionary');

my $tst2 = Krawfish::Index::Store::Dynamic::Dictionary->new;

$tst2->insert('abc');
$tst2->insert('zab');
$tst2->insert('dij');
$tst2->insert('ytz');
$tst2->insert('mkl');

# Create new dynamic dictionary object
ok(my $tst = Krawfish::Index::Store::Dynamic::Dictionary->new, 'Construct new tst');
ok($tst->insert('abc', 1), 'Insertion');
ok($tst->insert('abb', 2), 'Insertion');
ok($tst->insert('ab', 3), 'Insertion');
ok($tst->insert('bc', 4), 'Insertion');

is($tst->search('ab'), 3, 'ab is part of the TST');
is($tst->search('abb'), 2, 'abb is part of the TST');
is($tst->search('abc'), 1, 'abc is part of the TST');
is($tst->search('bc'), 4, 'ab is part of the TST');

ok(!$tst->search('aba'), 'Not part of the TST');
ok(!$tst->search('a'), 'Not part of the TST');
ok(!$tst->search('bb'), 'Not part of the TST');
ok(!$tst->search('bca'), 'Not part of the TST');

ok(my $static = Krawfish::Index::Store::V1::Dictionary->from_dynamic($tst),
   'Construct new complete tst');

is($static->term_by_term_id(1), 'abc', 'Get term by term id');
is($static->term_by_term_id(2), 'abb', 'Get term by term id');
is($static->term_by_term_id(3), 'ab', 'Get term by term id');
is($static->term_by_term_id(4), 'bc', 'Get term by term id');

ok(!$static->term_by_term_id(6), 'No term available');

is($static->search('ab'), 3, 'ab is part of the TST');
is($static->search('abb'), 2, 'abb is part of the TST');
is($static->search('abc'), 1, 'abc is part of the TST');
is($static->search('bc'), 4, 'ab is part of the TST');

ok(!$tst->search('aba'), 'Not part of the TST');
ok(!$tst->search('a'), 'Not part of the TST');
ok(!$tst->search('bb'), 'Not part of the TST');
ok(!$tst->search('bca'), 'Not part of the TST');

done_testing;
__END__
