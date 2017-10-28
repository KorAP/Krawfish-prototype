use Test::More;
use Test::Krawfish;
use strict;
use warnings;

use_ok('Krawfish::Index');
use_ok('Krawfish::Koral');

my $index = Krawfish::Index->new;

ok_index($index, {
  id => 7,
  lang => 'en'
} => '<1:s>[Der][hey]</1>', 'Add complex document');
ok_index($index, {
  id => 3,
  lang => 'de'
} => '<1:s>[Der]</1>[Baum]', 'Add complex document');
ok_index($index, {
  id => 1,
  lang => 'de'
} => '<1:s>[Der]</1><2:s>[alte][graue][Baum]</2>', 'Add complex document');


my $koral = Krawfish::Koral->new;
my $qb = $koral->query_builder;
my $mb = $koral->compilation_builder;
my $cb = $koral->corpus_builder;

$koral->query($qb->span('s'));
$koral->compilation(
  $mb->aggregate(
    $mb->a_length
  )
);

is($koral->to_string,
   "compilation=[aggr=[length]],query=[<s>]",
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
   '[aggr=[length=total:[avg:1.75,freq:4,min:1,max:3,sum:7]]]'.
     '[matches=[0:0-2][1:0-1][2:0-1][2:1-4]]',
   'Stringification');


$koral = Krawfish::Koral->new;
$koral->query($qb->span('s'));
$koral->corpus(
  $cb->bool_or(
    $cb->class($cb->string('lang')->eq('en'), 1),
    $cb->class($cb->string('lang')->eq('de'), 2)
  )
);
$koral->compilation(
  $mb->aggregate(
    $mb->a_length
  )
);



ok($koral_query = $koral->to_query
     ->identify($index->dict)
     ->optimize($index->segment)
     ->compile
     ->inflate($index->segment), 'Optimization');

is(
  $koral_query->to_string,
  '[aggr=[length=total:[avg:1.75,freq:4,min:1,max:3,sum:7];'.
    'class1:[avg:2,freq:1,min:2,max:2,sum:2];'.
    'class2:[avg:1.66666666666667,freq:3,min:1,max:3,sum:5]]]'.
    '[matches=[0:0-2!1][1:0-1!2][2:0-1!2][2:1-4!2]]',
  'Stringification');


done_testing;
__END__
