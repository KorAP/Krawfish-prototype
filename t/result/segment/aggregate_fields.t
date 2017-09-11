use Test::More;
use Test::Krawfish;
use Data::Dumper;
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
my $mb = $koral->meta_builder;

$koral->query($qb->token('aa'));

# Create meta query to aggregate on 'genre' and 'age'
$koral->meta(
  $mb->aggregate(
    $mb->a_fields('genre'),
    $mb->a_fields('age')
  )
);

is($koral->to_string,
   "meta=[aggr=[fields:['genre'],fields:['age']]],query=[[aa]]",
   'Stringification');

ok(my $koral_query = $koral->to_query, 'Normalization');

# This is a query that is fine to be send to nodes
is($koral_query->to_string,
   "aggr(fields:['genre','age']:filter(aa,[1]))",
   'Stringification');

# This is a query that is fine to be send to segments
ok($koral_query = $koral_query->identify($index->dict), 'Identify');


# This is a query that is fine to be send to nodes
is($koral_query->to_string,
   "aggr(fields:[#1,#5]:filter(#10,[1]))",
   'Stringification');

ok(my $query = $koral_query->optimize($index->segment),
   'Queryfication');

is($query->to_string, 'aggr([fields:#1,#5]:filter(#10,[1]))', 'Stringification');

ok($query->next, 'Next');
ok($query->next, 'Next');
ok($query->next, 'Next');
ok($query->next, 'Next');
ok($query->next, 'Next');
ok(!$query->next, 'No more nexts');

# TODO:
#   This API is only temporarily implemented
ok(my $coll = $query->collection->{fields}->inflate($index->dict), 'To terms');
is($coll->to_string, 'fields=age:3[1,1],4[2,3],7[1,1];genre:newsletter[2,3],novel[2,2]');


# Create meta query to aggregate on 'author'
$koral->meta(
  $mb->aggregate(
    $mb->a_fields('author')
  )
);

# Check with multivalued fields
ok($query = $koral->to_query->identify($index->dict)->optimize($index->segment), 'Translate');

is($query->to_string, 'aggr([fields:#3]:filter(#10,[1]))', 'Stringification');
ok($query->finalize, 'Finalize');

ok($coll = $query->collection->{fields}->inflate($index->dict), 'To terms');
is($coll->to_string, 'fields=author:Fritz[1,2],Michael[1,1],Peter[3,4]');


done_testing;
__END__


$hash = $aggr->result->{facets}->{corpus};
is($hash->{'corpus-2'}->[0], 2, 'Document frequency');
is($hash->{'corpus-2'}->[1], 2, 'frequency');

is_deeply($aggr->result, {
  facets => {
    license => {
      free => [1,1],
      closed => [1,1]
    },
    corpus => {
      'corpus-2' => [2,2]
    }
  }
}, 'aggregated results');


TODO: {
  local $TODO = 'Test with multivalued fields';
};

done_testing;
__END__
