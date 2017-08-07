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
   "enrich(fields:['id']:sort(field='id'<:aggr(freq:filter(bb,[1]))))",
   'Stringification');

# This is a query that is fine to be send to segments:
ok($koral_query = $koral_query->identify($index->dict), 'Identify');


# This is a query that is fine to be send to nodes
is($koral_query->to_string,
   "enrich(fields:[#2]:sort(field=#2<:aggr(freq:filter(#4,[1]))))",
   'Stringification');

diag 'check frequencies! First priority';





done_testing;
__END__

# Create new frequency criterion
my $freq = Krawfish::Result::Segment::Aggregate::Frequencies->new;
is($freq->to_string, 'freq');

# Get aggregation object with frequency criterion
ok(my $aggr = Krawfish::Result::Segment::Aggregate->new(
  $query->normalize->finalize->identify($index->dict)->optimize($index->segment),
  [$freq]
), 'Create freq object');

ok($aggr->next, 'Next');
ok($aggr->next, 'Next');
ok(!$aggr->next, 'No more nexts');


is($aggr->result->{totalResources}, 2, 'Document frequency');
is($aggr->result->{totalResults}, 2, 'Occurrence frequency');

is($aggr->to_string, "aggregate([freq]:#3)", 'Get freqs');
$query = $kq->token('cc');

$freq = Krawfish::Result::Segment::Aggregate::Frequencies->new;

# Get freq object
ok($aggr = Krawfish::Result::Segment::Aggregate->new(
  $query->normalize->finalize->identify($index->dict)->optimize($index->segment),
  [$freq]
), 'Create freq object');

# Search till the end
ok($aggr->finalize, 'Finish');

# Stringify
is($aggr->to_string, "aggregate([freq]:#5)", 'Get freqs');

is($aggr->result->{totalResources}, 1, 'Document frequency');
is($aggr->result->{totalResults}, 2, 'Occurrence frequency');

done_testing;
__END__
