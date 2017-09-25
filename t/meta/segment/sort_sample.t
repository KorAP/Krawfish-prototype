use Test::More;
use Test::Krawfish;
use Data::Dumper;
use strict;
use warnings;

use_ok('Krawfish::Index');
use_ok('Krawfish::Koral');

# TODO:
#   - limit is irrelevant on segment level,
#     but relevant to node and cluster

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
  author => 'Peter',
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

$koral->meta(
  $mb->sort_by(
    $mb->s_sample
  ),
  $mb->limit(0,2)
);

ok(my $query = $koral->to_query, 'Normalize');

is($query->to_string, 'sample(2:filter(aa,[1]))', 'Stringification');

ok($query = $query->identify($index->dict), 'Identify');

is($query->to_string, 'sample(2:filter(#10,[1]))', 'Stringification');

ok($query = $query->optimize($index->segment), 'Optimize');

is($query->to_string, 'sample(2:filter(#10,[1]))',
   'Stringification');

# The order of results is random
ok($query->next, 'Next');
ok($query->current_match, 'Match found');
ok($query->next, 'Next');
ok($query->current_match, 'Match found');
ok(!$query->next, 'Next');

done_testing;
__END__
