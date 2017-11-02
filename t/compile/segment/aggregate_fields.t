use Test::More;
use Test::Krawfish;
use Data::Dumper;
use Krawfish::Util::Constants qw/:PREFIX/;
use strict;
use warnings;

use_ok('Krawfish::Index');
use_ok('Krawfish::Koral');

# Create some documents
my $index = Krawfish::Index->new;
ok_index($index, {
  id => 2,
  author => 'Peter',
  genre => 'novel',
  age => 4
} => [qw/aa bb/], 'Add complex document');
ok_index($index, {
  id => 3,
  author => 'Peter',
  genre => 'novel',
  age => 3
} => [qw/aa bb/], 'Add complex document');
ok_index($index, {
  id => 5,
  author => ['Peter', 'Fritz'],
  genre => 'newsletter',
  title => 'Your way to success!',
  age => 4
} => [qw/aa bb aa/], 'Add complex document');
ok_index($index, {
  id => 6,
  author => 'Fritz',
  genre => 'newsletter',
  age => 3
} => [qw/bb/], 'Add complex document');
ok_index($index, {
  id => 7,
  author => 'Michael',
  genre => 'newsletter',
  age => 7
} => [qw/aa bb/], 'Add complex document');


my $koral = Krawfish::Koral->new;
my $qb = $koral->query_builder;
my $cb = $koral->corpus_builder;
my $mb = $koral->compilation_builder;

$koral->query($qb->token('aa'));

# Create compile query to aggregate on 'genre' and 'age'
$koral->compilation(
  $mb->aggregate(
    $mb->a_fields('genre'),
    $mb->a_fields('age')
  )
);

is($koral->to_string,
   "compilation=[aggr=[fields:['genre'],fields:['age']]],query=[[aa]]",
   'Stringification');

ok(my $koral_query = $koral->to_query, 'Normalization');

# This is a query that is fine to be send to nodes
is($koral_query->to_string,
   "aggr(fields:['genre','age']:filter(aa,[1]))",
   'Stringification');

# This is a query that is fine to be send to segments
ok($koral_query = $koral_query->identify($index->dict), 'Identify');

# This is a query that is fine to be send to nodes
is($koral_query->to_string(1),
   "aggr(fields:[#1,#5]:filter(#10,[1]))",
   'Stringification');

ok(my $query = $koral_query->optimize($index->segment),
   'Queryfication');

is($query->to_string, 'aggr([fields:#1,#5]:filter(#10,[1]))', 'Stringification');

ok(my $coll = $query->compile, 'Compile');
ok($coll = $coll->inflate($index->dict), 'To terms');

is($coll->to_string,
   '[aggr=[fields=total:['.
     'age=3:[1,1],4:[2,3],7:[1,1];'.
     'genre=newsletter:[2,3],novel:[2,2]]]]'.
     '[matches=[0:0-1][1:0-1][2:0-1][2:2-3][4:0-1]]',
   'Stringification');


# Create compile query to aggregate on 'author'
$koral->compilation(
  $mb->aggregate(
    $mb->a_fields('author')
  )
);

# Check with multivalued fields
ok($query = $koral->to_query->identify($index->dict)->optimize($index->segment), 'Translate');

is($query->to_string, 'aggr([fields:#3]:filter(#10,[1]))', 'Stringification');

ok($coll = $query->compile->inflate($index->dict), 'To terms');

is($coll->to_string,
   '[aggr=[fields=total:[author=Fritz:[1,2],Michael:[1,1],Peter:[3,4]]]]' .
     '[matches=[0:0-1][1:0-1][2:0-1][2:2-3][4:0-1]]',
   'Stringification'
 );


# Create compile query to aggregate on 'author'
$koral->compilation(
  $mb->aggregate(
    $mb->a_fields('author')
  )
);


# Define some classes
$koral->corpus(
  $cb->bool_or(
    $cb->class($cb->string('genre')->eq('newsletter'), 1),
    $cb->class($cb->string('genre')->eq('novel'), 2)
  )
);

# Check with multivalued fields
ok($query = $koral->to_query->identify($index->dict)->optimize($index->segment), 'Translate');

is($query->to_string, 'aggr([fields:#3]:filter(#10,or(class(2:#6),class(1:#16))))', 'Stringification');

ok($coll = $query->compile->inflate($index->dict), 'To terms');

is($coll->to_string,
   '[aggr=[fields='.
     'total:[author=Fritz:[1,2],Michael:[1,1],Peter:[3,4]];'.
     'inCorpus-1:[author=Fritz:[1,2],Michael:[1,1],Peter:[1,2]];'.
     'inCorpus-2:[author=Peter:[2,2]]]]'.
     '[matches=[0:0-1!2][1:0-1!2][2:0-1!1][2:2-3!1][4:0-1!1]]',
   'Stringification'
 );

ok($coll = $coll->to_koral_query->{aggregation}->{fields}, 'KQ Serialization');

is($coll->{total}->{author}->{Peter}->{docs}, 3, 'Values');
is($coll->{total}->{author}->{Peter}->{matches}, 4, 'Values');
is($coll->{total}->{author}->{Fritz}->{matches}, 2, 'Values');
is($coll->{total}->{author}->{Michael}->{matches}, 1, 'Values');
is($coll->{'inCorpus-1'}->{author}->{Fritz}->{matches}, 2, 'Values');


done_testing;
__END__
