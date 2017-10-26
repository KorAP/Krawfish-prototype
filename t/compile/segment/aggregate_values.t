use Test::More;
use Test::Krawfish;
use strict;
use warnings;

use_ok('Krawfish::Index');
use_ok('Krawfish::Koral');

my $index = Krawfish::Index->new;

ok_index($index, {
  integer_id => 7,
  integer_size => 2,
} => [qw/aa bb/], 'Add complex document');
ok_index($index, {
  integer_id => 3,
  integer_size => 3,
} => [qw/aa cc cc/], 'Add complex document');
ok_index($index, {
  integer_id => 1,
  integer_size => 2,
} => [qw/aa bb/], 'Add complex document');


# Only search for documents containing 'bb'
my $koral = Krawfish::Koral->new;
my $qb = $koral->query_builder;
my $mb = $koral->compilation_builder;

$koral->query($qb->token('bb'));

$koral->compilation(
  $mb->aggregate(
    $mb->a_values('size'),
    $mb->a_values('id')
  )
);

is(
  $koral->to_string,
  "compilation=[aggr=[values:['size'],values:['id']]],query=[[bb]]",
  'Stringification'
);

ok(my $koral_query = $koral->to_query, 'Normalization');

# This is a query that is fine to be send to nodes
is($koral_query->to_string,
   "aggr(values:['size','id']:filter(bb,[1]))",
   'Stringification');

# This is a query that is fine to be send to segments:
ok($koral_query = $koral_query->identify($index->dict), 'Identify');


# This is a query that is fine to be send to nodes
is($koral_query->to_string(1),
   "aggr(values:[#1,#3]:filter(#8,[1]))",
   'Stringification');

ok(my $query = $koral_query->optimize($index->segment), 'Optimize');

# may very well be renamed to search()

ok(my $result = $query->compile->inflate($index->dict),
   'Inflate fields');

is($result->to_string,
   '[aggr=[values='.
     'id:[sum:8,freq:2,min:1,max:7,avg:4];'.
     'size:[sum:4,freq:2,min:2,max:2,avg:2]]'.
     ']'.
     '[matches=[0:1-2][2:1-2]]',
   'Stringification');


$koral = Krawfish::Koral->new;
$koral->query($qb->token($qb->bool_or('bb','cc')));
$koral->compilation($mb->aggregate($mb->a_values('size')));

# The whole search flow
ok(my $coll = $koral->to_query
     ->identify($index->dict)
     ->optimize($index->segment)
     ->compile
     ->inflate($index->dict),
   'Query');

# This may differ from system to system
is($coll->to_string,
   '[aggr=[values=size:[sum:7,freq:3,min:2,max:3,avg:2.33333333333333]]]'.
     '[matches=[0:1-2][1:1-2][1:2-3][2:1-2]]',
   'Stringification');

diag 'Test with corpus classes';

done_testing;
__END__
