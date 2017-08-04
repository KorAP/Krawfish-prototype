use Test::More;
use Test::Krawfish;
use strict;
use warnings;

use_ok('Krawfish::Index');
use_ok('Krawfish::Koral');

my $index = Krawfish::Index->new;

ok_index($index, {
  id => 7
} => '<1:s>[Der][hey]</1>', 'Add complex document');
ok_index($index, {
  id => 3,
} => '<1:s>[Der]</1>[Baum]', 'Add complex document');
ok_index($index, {
  id => 1,
} => '<1:s>[Der]</1><2:s>[alte][graue][Baum]</2>', 'Add complex document');


my $koral = Krawfish::Koral->new;
my $qb = $koral->query_builder;
my $mb = $koral->meta_builder;

$koral->query($qb->span('s'));
$koral->meta(
  $mb->aggregate(
    $mb->a_length
  )
);

is($koral->to_string,
   "meta=[aggr=[length]],query=[<s>]",
   'Stringification');

ok(my $koral_query = $koral->to_query, 'Normalization');

# This is a query that is fine to be send to nodes
is($koral_query->to_string,
   "fields('id':sort(field='id'<:aggr(length:filter(<s>,[1]))))",
   'Stringification');

# This is a query that is fine to be send to segments:
ok($koral_query = $koral_query->identify($index->dict),
   'Identify');

# This is a query that is fine to be send to nodes
is($koral_query->to_string,
   "fields(#2:sort(field=#2<:aggr(length:filter(#4,[1]))))",
   'Stringification');

diag 'check lengths!';


done_testing;
__END__

my $length = Krawfish::Result::Segment::Aggregate::Length->new;

# Get length object
ok(my $aggr = Krawfish::Result::Segment::Aggregate->new(
  $query->normalize->finalize->optimize($index),
  [$length]
), 'Create length object');

is($aggr->to_string, q!aggregate([length]:'<>s')!, 'Stringification');

ok($aggr->next, 'Next');
ok($aggr->next, 'Next');
ok($aggr->next, 'Next');
ok($aggr->next, 'Next');
ok(!$aggr->next, 'No more nexts');

is_deeply($aggr->result, {
  length => {
    avg => 1.75,
    min => 1,
    max => 3,
    sum => 7
  }
}, 'Get aggregation results');


done_testing;
__END__
