use Test::More;
use Test::Krawfish;
use strict;
use warnings;

use_ok('Krawfish::Index');
use_ok('Krawfish::Koral');

my $index = Krawfish::Index->new;

ok_index($index, {
  id => 7,
  license => 'free'
} => [qw/aa bb/], 'Add complex document');
ok_index($index, {
  id => 3,
  license => 'close'
} => [qw/aa cc cc/], 'Add complex document');
ok_index($index, {
  id => 1,
  license => 'free'
} => [qw/aa bb/], 'Add complex document');


my $koral = Krawfish::Koral->new;
my $cb = $koral->corpus_builder;
my $qb = $koral->query_builder;
my $mb = $koral->compile_builder;

$koral->query($qb->token('bb'));

$koral->compile(
  $mb->aggregate(
    $mb->a_frequencies
  )
);

is($koral->to_string,
   "compile=[aggr=[freq]],query=[[bb]]",
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

is($query->compile->to_string,
   '[aggr=[freq=total:[2,2]]][matches=[0:1-2][2:1-2]]',
   'Aggregation');


# Test with imbalance regarding docs and matches
$koral = Krawfish::Koral->new;
$koral->query($qb->token('cc'));
$koral->compile(
  $mb->aggregate(
    $mb->a_frequencies
  )
);

ok($query = $koral->to_query->identify($index->dict)->optimize($index->segment),
   'Optimization');

# Stringify
# is($query->to_string, "aggr([freq]:filter(#9,[1]))", 'Get freqs');

# Search till the end
is($query->compile->to_string,
   '[aggr=[freq=total:[1,2]]][matches=[1:1-2][1:2-3]]',
   'Finish');



# Test aggregation with corpus classes
$koral->corpus(
  $cb->bool_or(
    $cb->class($cb->string('license')->eq('free'), 1),
    $cb->class($cb->string('license')->eq('close'), 2)
  )
);
$koral->query(
  $qb->seq(
    $qb->token('aa'),
    $qb->repeat(
      $qb->bool_or(
        $qb->token('bb'),
        $qb->token('cc')
      ),0,100)
  )
);

$koral->compile(
  $mb->aggregate(
    $mb->a_frequencies
  )
);

ok($query = $koral->to_query, 'To query');
is($query->to_string,
   'aggr(freq:filter(aa((bb)|(cc)){0,100},{1:license=free}|{2:license=close}))',
   'Stringification');

ok($query = $query->identify($index->dict)->optimize($index->segment),
   'Optimization');

# Search till the end
is($query->compile->to_string,
   '[aggr=[freq=total:[3,7];class1:[2,4];class2:[1,3]]]'.
     '[matches=[0:0-1][0:0-2][1:0-1][1:0-2][1:0-3][2:0-1][2:0-2]]',
   'Finish');

done_testing;
__END__
