use Test::More;
use Test::Krawfish;
use strict;
use warnings;

use_ok('Krawfish::Index');
use_ok('Krawfish::Koral');

my $index = Krawfish::Index->new;

ok_index($index, {
  id => 7,
  author => 'Carol'
} => [qw/aa bb/], 'Add complex document');
ok_index($index, {
  id => 3,
  author => 'Arthur'
} => [qw/aa bb cc/], 'Add complex document');
ok_index($index, {
  id => 1,
  author => 'Bob'
} => [qw/aa bb cc/], 'Add complex document');

my $koral = Krawfish::Koral->new;
my $qb = $koral->query_builder;
my $mb = $koral->compile_builder;

# Set query
$koral->query($qb->bool_or('aa', 'bb'));

# Set compile
$koral->compile(
  $mb->sort_by(
    $mb->s_field('id')
  )
);


is($koral->to_string,
   "compile=[sort=[field='id'<]],query=[aa|bb]",
   'Stringification');


ok(my $koral_query = $koral->to_query, 'Normalization');


# This is a query that is fine to be send to nodes
is($koral_query->to_string,
   "sort(field='id'<:filter(aa|bb,[1]))",
   'Stringification');

# This is a query that is fine to be send to segments:
ok($koral_query = $koral_query->identify($index->dict), 'Identify');


# This is a query that is fine to be send to nodes
is($koral_query->to_id_string,
   "sort(field=#3<:filter(#6|#8,[1]))",
   'Stringification');

ok($koral_query = $koral_query->optimize($index->segment), 'Optimize');

#is($koral_query->to_string,
#   '',
#   'Stringification');


diag 'check sorting';


done_testing;
__END__



# Get sort object
ok(my $sort = Krawfish::Result::Sort->new(
  $query->normalize->finalize->optimize($index),
  $index,
  ['docID']
), 'Create sort object');

is($sort->freq, 6, 'List has frequency');
ok($sort->next, 'Next');
is($sort->current->doc_id, 2, 'Obj');
ok($sort->next, 'Next');
is($sort->current->doc_id, 2, 'Obj');
ok($sort->next, 'Next');
is($sort->current->doc_id, 1, 'Obj');
ok($sort->next, 'Next');
is($sort->current->doc_id, 1, 'Obj');
ok($sort->next, 'Next');
is($sort->current->doc_id, 0, 'Obj');
ok($sort->next, 'Next');
is($sort->current->doc_id, 0, 'Obj');
ok(!$sort->next, 'No more nexts');

is($sort->to_string, "resultSorted(['docID']:or('aa','bb'))", 'Get counts');


$query = $kq->term('cc');

# Get sort object
ok($sort = Krawfish::Result::Sort->new(
  $query->normalize->finalize->optimize($index),
  $index,
  ['author']
), 'Create sort object');

is($sort->freq, 2, 'List has frequency');
ok($sort->next, 'Next');
is($sort->current->doc_id, 1, 'Obj');
ok($sort->next, 'Next');
is($sort->current->doc_id, 2, 'Obj');
ok(!$sort->next, 'No more nexts');

is($sort->to_string, "resultSorted(['author']:'cc')", 'Get counts');


done_testing;
__END__



