use Test::More;
use strict;
use warnings;

use_ok('Krawfish::Index::Store::Dynamic::Dictionary');

ok(my $tst = Krawfish::Index::Store::Dynamic::Dictionary->new, 'Construct new tst');

ok($tst->insert('Auster', 1), 'Insertion');

ok($tst->insert('Fragen', 2), 'Insertion');
ok($tst->insert('Baum', 3), 'Insertion');
ok($tst->insert('Charisma', 4), 'Insertion');
ok($tst->insert('Gewohnheit', 5), 'Insertion');
ok($tst->insert('Ehrlichkeit', 6), 'Insertion');
ok($tst->insert('Daumen', 7), 'Insertion');

is($tst->search('Baum'), 3, 'Found Baum');
ok(!$tst->search('Bäumling'), 'Did not found Bäumling');

done_testing;
