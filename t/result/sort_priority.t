use Test::More;
use Test::Krawfish;
use strict;
use warnings;

use_ok('Krawfish::Index');
use_ok('Krawfish::Koral::Query::Builder');
use_ok('Krawfish::Result::Sort::Priority');

my $index = Krawfish::Index->new;

ok_index($index, {
  docID => 7,
  author => 'Carol'
} => [qw/aa bb/], 'Add complex document');
ok_index($index, {
  docID => 3,
  author => 'Arthur'
} => [qw/aa bb cc/], 'Add complex document');
ok_index($index, {
  docID => 1,
  author => 'Bob'
} => [qw/aa bb cc/], 'Add complex document');

my $kq = Krawfish::Koral::Query::Builder->new;

my $query = $kq->bool_or('aa', 'bb');

# Set maximum rank reference to the last doc id of the index
my $max_rank = $index->max_rank;

# Get sort object
ok(my $sort = Krawfish::Result::Sort::Priority->new(
  query => $query->normalize->finalize->optimize($index),
  field => 'docID',
  fields => $index->fields,
  top_k => 2,
  max_rank_ref => \$max_rank
), 'Create sort object');

# This will be sorted by the doc id,
# so the doc-id=1 document will show up first
ok($sort->next, 'First next');

is($sort->current->doc_id, 2, 'Obj');
ok($sort->next, 'Next');
is($sort->current->doc_id, 2, 'Obj');
ok(!$sort->next, 'No more next');

# Next try
$max_rank = $index->max_rank;
ok($sort = Krawfish::Result::Sort::Priority->new(
  query => $query->normalize->finalize->optimize($index),
  fields => $index->fields,
  field => 'docID',
  desc => 1,
  top_k => 3,
  max_rank_ref => \$max_rank
), 'Create sort object');

# Although top_k is set,
# the list exceeds the limit
ok($sort->next, 'First next');
is($sort->current->doc_id, 0, 'Obj');
is($sort->duplicate_rank, 2, 'Duplicates');
ok($sort->next, 'Next');
is($sort->current->doc_id, 0, 'Obj');
is($sort->duplicate_rank, 1, 'Duplicates');
ok($sort->next, 'No more next');
is($sort->current->doc_id, 1, 'Obj');
is($sort->duplicate_rank, 2, 'Duplicates');
ok($sort->next, 'No more next');
is($sort->current->doc_id, 1, 'Obj');
is($sort->duplicate_rank, 1, 'Duplicates');
ok(!$sort->next, 'No more next');

is($sort->to_string, "prioritySort(^,docID:or('aa','bb'))", 'Stringification');

done_testing;
__END__


