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
  author => 'Julian',
  genre => 'novel',
  age => 3
} => [qw/aa bb/], 'Add complex document');
ok_index($index, {
  id => 5,
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

$koral->query(
  $qb->seq(
    $qb->token('aa'),
    $qb->token('bb')
  )
);

$koral->meta(
  $mb->sort_by(
    $mb->s_field('author')
  ),
  $mb->limit(1,3)
);

ok(my $query = $koral->to_query, 'Normalize');

is($query->to_string, "limit(1-4:sort(field='author'<,field='id'<;k=4;sortFilter:filter(aabb,[1])))", 'Stringification');

ok($query = $query->identify($index->dict), 'Identify');

is($query->to_string,
   'limit(1-4:sort(field=#3<,field=#7<;k=4;sortFilter:filter(#10#12,[1])))',
   'Stringification');

diag 'Reimplement field sorting';

done_testing;
__END__



ok($query = $query->optimize($index->segment), 'Optimize');




is($query->to_string, 'resultLimit([0-2]:sample(2:filter(#10,[1])))',
   'Stringification');

# The order of results is random
ok($query->next, 'Next');
ok($query->current_match, 'Match found');
ok($query->next, 'Next');
ok($query->current_match, 'Match found');
ok(!$query->next, 'Next');

