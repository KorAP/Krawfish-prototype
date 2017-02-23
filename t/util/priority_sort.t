#!/url/bin/env perl
use strict;
use warnings;
use Test::More;

use_ok('Krawfish::Util::PrioritySort');

my $max_rank = 800_000;
my $max_rank_ref = \$max_rank;

ok(my $sorter = Krawfish::Util::PrioritySort->new(5, $max_rank_ref), 'Create priority sorter');

ok( $sorter->insert(20,     'Baum 1'),  'Add record to sorter - 20');
ok( $sorter->insert(44,     'Baum 2'),  'Add record to sorter - 44');
ok( $sorter->insert(4_000,  'Baum 3'),  'Add record to sorter - 4_000');
ok( $sorter->insert(18_000, 'Baum 4'),  'Add record to sorter - 18_000');
ok( $sorter->insert(25_000, 'Baum 5'),  'Add record to sorter - 25_000');
ok(!$sorter->insert(26_000, 'Baum 6'),  'Not relevant any more');
ok( $sorter->insert(5,      'Baum 7'),  'Add record to sorter - 5');

is($sorter->max_rank, 18_000, 'Check new max rank');


ok(!$sorter->insert(32_000, 'Baum 8'),  'Not relevant any more');
ok( $sorter->insert(15_000, 'Baum 9'),  'Add record to sorter - 15_000');
is($sorter->max_rank, 15_000, 'Check new max rank');

# Add some duplicates at the end of the queue
ok( $sorter->insert(15_000, 'Baum 10'),  'Add record to sorter - 15_000');
ok( $sorter->insert(15_000, 'Baum 11'),  'Add record to sorter - 15_000');
ok( $sorter->insert(15_000, 'Baum 12'),  'Add record to sorter - 15_000');

ok( $sorter->insert(44, 'Baum 13'),  'Add record to sorter - 44');
is($sorter->max_rank, 4_000, 'Check new max rank');

ok( $sorter->insert(5, 'Baum 14'),  'Add record to sorter - 5');
is($sorter->max_rank, 44, 'Check new max rank');

ok( $sorter->insert(44, 'Baum 15'),  'Add record to sorter - 44');

ok( $sorter->insert(2, 'Baum 16'),  'Add record to sorter - 2');
is($sorter->max_rank, 44, 'Check new max rank');

ok( $sorter->insert(15, 'Baum 17'),  'Add record to sorter - 15');
is($sorter->max_rank, 20, 'Check new max rank');

ok( $sorter->insert(5, 'Baum 18'),  'Add record to sorter - 5');
is($sorter->max_rank, 15, 'Check new max rank');

ok( $sorter->insert(5, 'Baum 19'),  'Add record to sorter - 5');
is($sorter->max_rank, 5, 'Check new max rank');

ok( $sorter->insert(5, 'Baum 20'),  'Add record to sorter - 5');
is($sorter->max_rank, 5, 'Check new max rank');

ok( $sorter->insert(5, 'Baum 21'),  'Add record to sorter - 5');
is($sorter->max_rank, 5, 'Check new max rank');
is($sorter->length, 7, 'Length');

ok( $sorter->insert(5, 'Baum 22'),  'Add record to sorter - 5');
is($sorter->max_rank, 5, 'Check new max rank');
is($sorter->length, 8, 'Length');

ok( $sorter->insert(3, 'Baum 23'),  'Add record to sorter - 3');
is($sorter->max_rank, 5, 'Check new max rank');
is($sorter->length, 9, 'Length');

ok( $sorter->insert(4, 'Baum 24'),  'Add record to sorter - 4');
is($sorter->max_rank, 5, 'Check new max rank');
is($sorter->length, 10, 'Length');

ok( $sorter->insert(1, 'Baum 25'),  'Add record to sorter - 1');
is($sorter->max_rank, 5, 'Check new max rank');
is($sorter->length, 11, 'Length');

ok( $sorter->insert(4, 'Baum 26'),  'Add record to sorter - 4');
is($sorter->max_rank, 4, 'Check new max rank');

is($sorter->length, 5, 'Length');




done_testing;
__END__

