use Test::More;
use Test::Krawfish;
use Data::Dumper;
use strict;
use warnings;

use_ok('Krawfish::Index');
use_ok('Krawfish::Koral');

# Create some documents
my $index = Krawfish::Index->new;

ok($index->introduce_field('id', 'NUM'), 'Introduce field as sortable');
ok($index->introduce_field('author', 'DE'), 'Introduce field as sortable');
ok($index->introduce_field('genre', 'DE'), 'Introduce field as sortable');
ok($index->introduce_field('title', 'DE'), 'Introduce field as sortable');

ok_index($index, {
  id => 2,
  author => 'Peter',
  genre => 'novel',
  age => 4
} => [qw/aa bb/], 'Add complex document');
ok_index($index, {
  id => 3,
  author => 'Julian',
  genre => 'novel',
  age => 3
} => [qw/bb/], 'Add complex document');
ok_index($index, {
  id => 1,
  author => 'Abraham',
  genre => 'newsletter',
  title => 'Your way to success!',
  age => 4
} => [qw/aa bb aa/], 'Add complex document');
ok_index($index, {
  id => 6,
  author => 'Fritz',
  genre => 'newsletter',
  age => 3
} => [qw/aa bb/], 'Add complex document');
ok_index($index, {
  id => 5,
  author => 'Michael',
  genre => 'newsletter',
  title => 'Your new way to success!',
  age => 7
} => [qw/aa bb/], 'Add complex document');

ok($index->commit, 'Commit data');

my $koral = Krawfish::Koral->new;
my $qb = $koral->query_builder;
my $mb = $koral->compilation_builder;
my ($query, $result, $clone);

$koral->query(
  $qb->seq(
    $qb->token('aa'),
    $qb->token('bb')
  )
);

$koral->compilation(
  $mb->sort_by(
    $mb->s_field('title'),
    $mb->s_field('id')
  ),
  $mb->aggregate(
    $mb->a_frequencies,
    $mb->a_fields('genre')
  )
);

ok($query = $koral->to_query, 'Normalize');

ok($query = $query->identify($index->dict)->optimize($index->segment), 'optimize');

is($query->to_string(1),
   'sort(field=#1<,l=1:sort(field=#4<:bundleDocs(aggr([freq,fields:#3]:constr(pos=2:#11,filter(#13,[1]))))))',
   'Stringification');

is($query->compile->inflate($index->dict)->to_string,
   '[aggr='.
     '[freq=total:[4,4]][fields=total:[genre=newsletter:[3,3],novel:[1,1]]]'.
   ']'.
   '[matches='.
     '[4:0-2::G80..AA=,5]'.
     '[2:0-2::G80..wAA,1]'.
     '[0:0-2::-,2]'.
     '[3:0-2::-,6]'.
   ']',
   'Stringification');

done_testing;
__END__
