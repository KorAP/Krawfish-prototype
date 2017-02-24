use Test::More;
use Test::Krawfish;
use strict;
use warnings;

use_ok('Krawfish::Index');
use_ok('Krawfish::Koral::Query::Builder');
use_ok('Krawfish::Result::Sort::InitRank');

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

my $query = $kq->term_or('aa', 'bb');

# Get sort object
my $max_rank = 80_000;
ok(my $sort = Krawfish::Result::Sort::InitRank->new(
  query => $query->prepare_for($index),
  field_rank => $index->fields->ranked_by('docID'),
  top_k => 2,
  max_rank_ref => \$max_rank
), 'Create sort object');

ok($sort->next, 'First next');
is($sort->current->doc_id, 2, 'Obj');
ok($sort->next, 'Next');
is($sort->current->doc_id, 2, 'Obj');
ok(!$sort->next, 'No more next');

done_testing;
__END__

is($sort->freq, 6, 'List has frequency');
ok($sort->next, 'Next');
is($sort->current->doc_id, 1, 'Obj');
ok($sort->next, 'Next');
is($sort->current->doc_id, 1, 'Obj');
ok($sort->next, 'Next');
is($sort->current->doc_id, 0, 'Obj');
ok($sort->next, 'Next');
is($sort->current->doc_id, 0, 'Obj');
ok(!$sort->next, 'No more nexts');

is($sort->to_string, "collectSorted(['docID']:or('aa','bb'))", 'Get counts');


$query = $kq->term('cc');

# Get sort object
ok($sort = Krawfish::Result::Sort->new(
  $query->prepare_for($index),
  $index,
  ['author']
), 'Create sort object');

is($sort->freq, 2, 'List has frequency');
ok($sort->next, 'Next');
is($sort->current->doc_id, 1, 'Obj');
ok($sort->next, 'Next');
is($sort->current->doc_id, 2, 'Obj');
ok(!$sort->next, 'No more nexts');

is($sort->to_string, "collectSorted(['author']:'cc')", 'Get counts');


done_testing;
__END__



