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
my $mb = $koral->meta_builder;

$koral->query(
  $qb->bool_or('aa', 'bb')
);

$koral->meta(
  $mb->limit(1,2)
);

is($koral->to_string,
   "meta=[limit=[1-3]],query=[aa|bb]",
   'Stringification');

ok(my $koral_query = $koral->to_query, 'Normalization');

# This is a query that is fine to be send to nodes
is($koral_query->to_string,
   "enrich(fields:['id']:limit(1-3:sort(field='id'<;k=3;sortFilter:filter(aa|bb,[1]))))",
   'Stringification');

# This is a query that is fine to be send to segments:
ok($koral_query = $koral_query->identify($index->dict), 'Identify');


# This is a query that is fine to be send to nodes
is($koral_query->to_string,
   "enrich(fields:[#4]:limit(1-3:sort(field=#4<;k=3;sortFilter:filter(#5|#6,[1]))))",
   'Stringification');


diag 'Check limiting';

done_testing;
__END__


# Get sort object
ok(my $sort = Krawfish::Result::Limit->new(
  $query->normalize->finalize->optimize($index),
  1,
  3
), 'Create sort object');

ok($sort->next, 'Next');
is($sort->current->doc_id, 1, 'Obj');
ok($sort->next, 'Next');
is($sort->current->doc_id, 2, 'Obj');
ok(!$sort->next, 'No more nexts');

# Better not stingify
is($sort->to_string, "resultLimit([1-4]:or('akron=Der','Der'))", 'Stringification');

