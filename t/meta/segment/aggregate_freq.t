use Test::More;
use Test::Krawfish;
use strict;
use warnings;

use_ok('Krawfish::Index');
use_ok('Krawfish::Koral');

my $index = Krawfish::Index->new;

ok_index($index, {
  id => 7
} => [qw/aa bb/], 'Add complex document');
ok_index($index, {
  id => 3,
} => [qw/aa cc cc/], 'Add complex document');
ok_index($index, {
  id => 1,
} => [qw/aa bb/], 'Add complex document');


my $koral = Krawfish::Koral->new;
my $qb = $koral->query_builder;
my $mb = $koral->meta_builder;

$koral->query($qb->token('bb'));

$koral->meta(
  $mb->aggregate(
    $mb->a_frequencies
  )
);

is($koral->to_string,
   "meta=[aggr=[freq]],query=[[bb]]",
   'Stringification');

ok(my $koral_query = $koral->to_query, 'Normalization');

# This is a query that is fine to be send to nodes
is($koral_query->to_string,
   "aggr(freq:filter(bb,[1]))",
   'Stringification');

# This is a query that is fine to be send to segments:
ok($koral_query = $koral_query->identify($index->dict), 'Identify');


# This is a query that is fine to be send to nodes
#is($koral_query->to_string,
#   "aggr(freq:filter(#6,[1]))",
#   'Stringification');

ok(my $query = $koral_query->optimize($index->segment), 'Optimization');

# is($query->to_string, 'aggr([freq]:filter(#6,[1]))', 'Stringification');

ok($query->next, 'Next');
ok($query->next, 'Next');
ok(!$query->next, 'No more nexts');

is($query->collection->{totalResources}, 2, 'Document frequency');
is($query->collection->{totalResults}, 2, 'Occurrence frequency');


$koral = Krawfish::Koral->new;
$koral->query($qb->token('cc'));
$koral->meta(
  $mb->aggregate(
    $mb->a_frequencies
  )
);

ok($query = $koral->to_query->identify($index->dict)->optimize($index->segment),
   'Optimization');

# Search till the end
ok($query->finalize, 'Finish');

# Stringify
# is($query->to_string, "aggr([freq]:filter(#9,[1]))", 'Get freqs');

is($query->collection->{totalResources}, 1, 'Document frequency');
is($query->collection->{totalResults}, 2, 'Occurrence frequency');



done_testing;
__END__
