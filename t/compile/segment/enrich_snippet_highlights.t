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
} => [qw/aa bb aa bb/], 'Add new document');

my $koral = Krawfish::Koral->new;
my $qb = $koral->query_builder;
my $mb = $koral->compilation_builder;
my ($koral_query, $query);

$koral->query(
  $qb->seq(
    $qb->token('aa'),
    $qb->class($qb->token('bb'), 2)
  )
);

$koral->compilation(
  $mb->enrich(
    $mb->e_snippet(
      highlights => [2]
    )
  )
);

is($koral->to_string,
   "compilation=[enrich=[snippet=[hit,hls:[2]]]],query=[[aa]{2:[bb]}]",
   'Stringification');

ok($koral_query = $koral->to_query, 'Normalization');

# This is a query that is fine to be send to nodes
is($koral_query->to_string,
   "snippet(hit,hls=[2]:filter(aa{2:bb},[1]))",
   'Stringification');

# This is a query that is fine to be send to segments:
ok($koral_query = $koral_query->identify($index->dict), 'Identify');

# This is a query that is fine to be send to nodes
is($koral_query->to_string(1),
   "snippet(hit,hls=[2]:filter(#8{2:#10},[1]))",
   'Stringification');

ok($query = $koral_query->optimize($index->segment), 'Optimize');
is ($query->to_string, 'eSnippet(hit:constr(pos=2:#8,class(2:filter(#10,[1]))))', 'Stringification');

# Check snippets multiple times
ok($query->next, 'Next match');
is($query->current_match->inflate($index->dict)
     ->to_string, "[0:0-2\$0,2,1,2|snippet:[aa {2:bb}]]",
   'Current match');


# Get snippet without highlight
$koral->query(
  $qb->seq(
    $qb->token('aa'),
    $qb->bool_or(
      $qb->class($qb->token('xx'), 1),
      $qb->class($qb->token('bb'), 2)
    )
  )
);

$koral->compilation(
  $mb->enrich(
    $mb->e_snippet(
      highlights => [1]
    )
  )
);

ok($koral_query = $koral->to_query, 'Normalization');

# This is a query that is fine to be send to nodes
is($koral_query->to_string,
   "snippet(hit,hls=[1]:filter(aa({1:xx})|({2:bb}),[1]))",
   'Stringification');

# This is a query that is fine to be send to segments:
ok($koral_query = $koral_query->identify($index->dict), 'Identify');

ok($query = $koral_query->optimize($index->segment), 'Optimize');

# Check snippets without highlights
ok($query->next, 'Next match');
is($query->current_match->inflate($index->dict)
     ->to_string, '[0:0-2$0,2,1,2|snippet:[aa bb]]',
   'Current match');



done_testing;
__END__
