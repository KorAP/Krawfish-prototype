#!/url/bin/env perl
use strict;
use warnings;
use Test::More;
use Data::Dumper;

use_ok('Krawfish::Util::PriorityQueue');

my $max_rank = 800_000;
my $max_rank_ref = \$max_rank;

ok(my $sorter = Krawfish::Util::PriorityQueue->new(5, $max_rank_ref), 'Create priority sorter');

sub node {
  return [$_[0], 0, $_[1]]
}

ok( $sorter->insert(node(20,     'Baum 1')),  'Add record to sorter - 20');
ok( $sorter->insert(node(44,     'Baum 2')),  'Add record to sorter - 44');
ok( $sorter->insert(node(4_000,  'Baum 3')),  'Add record to sorter - 4_000');
ok( $sorter->insert(node(18_000, 'Baum 4')),  'Add record to sorter - 18_000');
ok( $sorter->insert(node(25_000, 'Baum 5')),  'Add record to sorter - 25_000');
ok(!$sorter->insert(node(26_000, 'Baum 6')),  'Not relevant any more');
ok( $sorter->insert(node(5,      'Baum 7')),  'Add record to sorter - 5');

is($sorter->max_rank, 18_000, 'Check new max rank');
is($sorter->top_identical_nodes, 1, '1 top identical');

ok(!$sorter->insert(node(32_000, 'Baum 8')),  'Not relevant any more');
ok( $sorter->insert(node(15_000, 'Baum 9')),  'Add record to sorter - 15_000');
is($sorter->max_rank, 15_000, 'Check new max rank');
is($sorter->top_identical_nodes, 1, '1 top identical');

# Add some duplicates at the end of the queue
ok( $sorter->insert(node(15_000, 'Baum 10')),  'Add record to sorter - 15_000');
ok( $sorter->insert(node(15_000, 'Baum 11')),  'Add record to sorter - 15_000');
ok( $sorter->insert(node(15_000, 'Baum 12')),  'Add record to sorter - 15_000');
is($sorter->max_rank, 15_000, 'Check new max rank');
is($sorter->top_identical_nodes, 4, 'top identicals');

ok( $sorter->insert(node(44, 'Baum 13')),  'Add record to sorter - 44');
is($sorter->max_rank, 4_000, 'Check new max rank');
is($sorter->top_identical_nodes, 1, 'top identicals');

ok( $sorter->insert(node(5, 'Baum 14')),  'Add record to sorter - 5');
is($sorter->max_rank, 44, 'Check new max rank');
is($sorter->top_identical_nodes, 2, 'top identicals');

ok( $sorter->insert(node(44, 'Baum 15')),  'Add record to sorter - 44');
is($sorter->top_identical_nodes, 3, 'top identicals');


ok( $sorter->insert(node(2, 'Baum 16')),  'Add record to sorter - 2');
is($sorter->max_rank, 44, 'Check new max rank');
is($sorter->top_identical_nodes, 3, 'top identicals');

ok( $sorter->insert(node(15, 'Baum 17')),  'Add record to sorter - 15');
is($sorter->max_rank, 20, 'Check new max rank');
is($sorter->top_identical_nodes, 1, 'top identicals');

ok( $sorter->insert(node(5, 'Baum 18')),  'Add record to sorter - 5');
is($sorter->max_rank, 15, 'Check new max rank');
is($sorter->top_identical_nodes, 1, 'top identicals');

ok( $sorter->insert(node(5, 'Baum 19')),  'Add record to sorter - 5');
is($sorter->max_rank, 5, 'Check new max rank');
is($sorter->top_identical_nodes, 4, 'top identicals');

ok( $sorter->insert(node(5, 'Baum 20')),  'Add record to sorter - 5');
is($sorter->max_rank, 5, 'Check new max rank');
is($sorter->top_identical_nodes, 5, 'top identicals');

ok( $sorter->insert(node(5, 'Baum 21')),  'Add record to sorter - 5');
is($sorter->max_rank, 5, 'Check new max rank');
is($sorter->length, 7, 'Length');
is($sorter->top_identical_nodes, 6, '7 top identicals');

ok( $sorter->insert(node(5, 'Baum 22')),  'Add record to sorter - 5');
is($sorter->max_rank, 5, 'Check new max rank');
is($sorter->length, 8, 'Length');
is($sorter->top_identical_nodes, 7, '7 top identicals');

ok( $sorter->insert(node(3, 'Baum 23')),  'Add record to sorter - 3');
is($sorter->max_rank, 5, 'Check new max rank');
is($sorter->length, 9, 'Length');

ok( $sorter->insert(node(4, 'Baum 24')),  'Add record to sorter - 4');
is($sorter->max_rank, 5, 'Check new max rank');
is($sorter->length, 10, 'Length');

ok( $sorter->insert(node(1, 'Baum 25')),  'Add record to sorter - 1');
is($sorter->max_rank, 5, 'Check new max rank');
is($sorter->length, 11, 'Length');

ok( $sorter->insert(node(4, 'Baum 26')),  'Add record to sorter - 4');
is($sorter->max_rank, 4, 'Check new max rank');

is($sorter->length, 5, 'Length');

ok( $sorter->insert(node(4, 'Baum 27')),  'Add record to sorter - 4');
is($sorter->max_rank, 4, 'Check new max rank');

is_deeply($sorter->reverse_array, [
  [1,0,'Baum 25'],
  [2,0,'Baum 16'],
  [3,0,'Baum 23'],
  [4,3,'Baum 26'],
  [4,0,'Baum 27'],
  [4,0,'Baum 24'],
], 'Reverse array');

# Check with bug
$max_rank = 800_000;
$max_rank_ref = \$max_rank;
ok($sorter = Krawfish::Util::PriorityQueue->new(3, $max_rank_ref), 'Create priority sorter');

ok($sorter->insert(node(1,'Baum 1')), 'Added rank 0 (1)');
ok($sorter->insert(node(1,'Baum 2')), 'Added rank 0 (2)');
ok($sorter->insert(node(2,'Baum 3')), 'Added rank 1 (1)');
ok($sorter->insert(node(2,'Baum 4')), 'Added rank 1 (2)');

is($sorter->length, 4, 'Length');
is($sorter->top_identical_nodes, 2, 'top identicals');

my $array = $sorter->reverse_array;
is_deeply($array, [
  [1,2,'Baum 2'],
  [1,0,'Baum 1'],
  [2,2,'Baum 4'],
  [2,0,'Baum 3'],
], 'Reverse array');


done_testing;
__END__

