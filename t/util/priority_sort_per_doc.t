#!/url/bin/env perl
use strict;
use warnings;
use Test::More;
use Data::Dumper;

use_ok('Krawfish::Util::PriorityQueue::PerDoc');

my $max_rank = 800_000;
my $max_rank_ref = \$max_rank;

sub node {
  return [
    $_[0], # RANK
    0,     # SAME
    $_[2], # VALUE
    $_[1], # IN_DOC
    0      # IN_DOC_COMPLETE
  ]
};

# The Priority queue wants max 5 matches
ok(my $sorter = Krawfish::Util::PriorityQueue::PerDoc->new(5, $max_rank_ref),
   'Create priority sorter');

# Add a node with rank, document and value
ok($sorter->insert(node(20, 2, 'Baum 1; Baum 2')),  'Add records to sorter - 20/2');
ok($sorter->insert(node(12, 3, 'Baum 3; Baum 4; Baum 5')),  'Add records to sorter - 12/3');
is($sorter->length, 5, 'Length');

# Now there are already 5 documents
ok(!$sorter->insert(node(23, 3, 'Baum 6; Baum 7; Baum 8')),
   'Fail to add records to sorter - 23/3');

ok($sorter->insert(node(5, 1, 'Baum 9')), 'Add record to sorter - 5/1');
is($sorter->length, 6, 'Length');

ok($sorter->insert(node(5, 2, 'Baum 10')), 'Add record to sorter - 5/2');
is($sorter->length, 6, 'Length');

ok($sorter->insert(node(5, 7, 'Baum 11')), 'Add record to sorter - 5/7');
is($sorter->length, 10, 'Length');

ok($sorter->insert(node(5, 2, 'Baum 12')), 'Add record to sorter - 5/2');

is($sorter->length, 12, 'Length');

ok($sorter->insert(node(5, 5, 'Baum 13')), 'Add record to sorter - 5/5');

is($sorter->length, 17, 'Length');

ok($sorter->insert(node(4, 2, 'Baum 14')), 'Add record to sorter - 4/2');

is($sorter->length, 19, 'Length');

ok($sorter->insert(node(4, 1, 'Baum 15')), 'Add record to sorter - 4/1');

is($sorter->length, 20, 'Length');

ok($sorter->insert(node(4, 7, 'Baum 15')), 'Add record to sorter - 4/1');

is($sorter->length, 10, 'Length');

done_testing;
__END__
