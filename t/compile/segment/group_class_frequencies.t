use Test::More;
use Test::Krawfish;
use Krawfish::Util::Constants qw/:PREFIX/;
use strict;
use warnings;

use_ok('Krawfish::Index');
use_ok('Krawfish::Koral');

my $index = Krawfish::Index->new;
ok_index($index, {
  id => 'doc-1',
  license => 'free',
  corpus => 'corpus-2'
} => '[aa|xx][bb|xx][cc|yy]', 'Add new document');

ok_index($index, {
  id => 'doc-2',
  license => 'closed',
  corpus => 'corpus-3'
} => '[aa|xx][bb|yy][cc|xx]', 'Add new document');
ok_index($index, {
  id => 'doc-3',
  license => 'free',
  corpus => 'corpus-1',
  store_uri => 'My URL'
} => '[aa|xx][bb|yy][cc|yy]', 'Add new document');


my $koral = Krawfish::Koral->new;
my $qb = $koral->query_builder;
my $mb = $koral->compilation_builder;

$koral->query(
  $qb->seq(
    $qb->class($qb->token('xx'), 2),
    $qb->class($qb->token('yy'), 3)
  )
);

$koral->compilation(
  $mb->group_by(
    $mb->g_class_freq(2,3)
  )
);

is($koral->to_string,
   "compilation=[group=[classFreq:[2,3]]],query=[{2:[xx]}{3:[yy]}]",
   'Stringification');

ok(my $koral_query = $koral->to_query, 'Normalization');

# This is a query that is fine to be send to segments:
ok($koral_query = $koral_query->identify($index->dict), 'Identify');

# This is a query that is fine to be send to nodes
is($koral_query->to_string,
   "gClassFreq(2,3:filter({2:#9}{3:#14},[1]))",
   'Stringification');

ok(my $query = $koral_query->optimize($index->segment), 'optimize query');

is($query->to_string, 'gClassFreq(2,3:constr(pos=2:class(2:#9),class(3:filter(#14,[1]))))', 'Stringification');
ok($query->next, 'Go to next');
ok($query->finalize, 'Go to next');

ok(my $coll = $query->collection, 'Get collection');

ok($coll = $coll->inflate($index->dict), 'Collection');

is(
  $coll->to_string,
  "gClassFreq:[<2,'" . SUBTERM_PREF . "aa',3,'" . SUBTERM_PREF . "bb'>=2;<2,'" . SUBTERM_PREF . "bb',3,'" . SUBTERM_PREF . "cc'>=1]",
  'Stringification'
);


done_testing;
__END__
