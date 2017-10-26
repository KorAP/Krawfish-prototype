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
my $mb = $koral->compile_builder;

$koral->query($qb->span('s'));
$koral->compile(
  $mb->aggregate(
    $mb->a_length
  )
);

is($koral->to_string,
   "compile=[aggr=[length]],query=[<s>]",
   'Stringification');

ok(my $koral_query = $koral->to_query, 'Normalization');

# This is a query that is fine to be send to nodes
is($koral_query->to_string,
   "aggr(length:filter(<s>,[1]))",
   'Stringification');

# This is a query that is fine to be send to segments:
ok($koral_query = $koral_query->identify($index->dict),
   'Identify');

# This is a query that is fine to be send to nodes
#is($koral_query->to_string,
#   "aggr(length:filter(#5,[1]))",
#   'Stringification');

ok(my $query = $koral_query->optimize($index->segment), 'Optimization');

ok(my $coll = $query->compile->inflate($index->segment), 'Optimization');

is($coll->to_string,
   '[aggr=[length=[avg:1.75;min:1;max:3;sum:7]]' .
     '[matches=[0:0-2][1:0-1][2:0-1][2:1-4]]',
   'Stringification');

done_testing;
__END__
