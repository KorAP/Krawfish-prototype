use Test::More;
use Test::Krawfish;
use Krawfish::Util::Constants qw/:PREFIX/;
use strict;
use warnings;

use_ok('Krawfish::Index');
use_ok('Krawfish::Koral');

my $index = Krawfish::Index->new;
ok_index($index, {
  id => 1,
  license => 'free',
  corpus => 'corpus-2'
} => '<1:a/b=c>[aa]<2:a/b=c>[aa]</2>[dd][aa]</1>', 'Add new document');

my $koral = Krawfish::Koral->new;
my $qb = $koral->query_builder;
my $mb = $koral->compilation_builder;

$koral->query($qb->term('aa'));

$koral->compilation(
  $mb->enrich(
    $mb->e_snippet(
      context => $mb->e_span_context(SPAN_PREF . 'a/b=c')
    )
  )
);

is($koral->to_string,
   'compilation=[enrich=[snippet=[hit,left:span(a/b=c,0),right:span(a/b=c,0)]]],query=[aa]',
   'Stringification');

ok(my $koral_query = $koral->to_query, 'Normalization');

# This is a query that is fine to be send to nodes
is($koral_query->to_string,
   'snippet(hit,left=span(a/b=c,0),right=span(a/b=c,0):filter(aa,[1]))',
   'Stringification');

# This is a query that is fine to be send to segments:
ok($koral_query = $koral_query->identify($index->dict), 'Identify');

# This is a query that is fine to be send to nodes
is($koral_query->to_string(1),
   'snippet(hit,left=span(#10/#11=#9,0),right=span(#10/#11=#9,0):filter(#8,[1]))',
   'Stringification');

ok(my $query = $koral_query->optimize($index->segment), 'Optimize');
is ($query->to_string,
    'eSnippet(hit,span(#10/#11=#9,0,4096),span(#10/#11=#9,0,4096):filter(#8,[1]))',
    'Stringification'
  );

ok($query->next, 'Next match');
my $match = $query->current_match;
is($match->to_string(1), "[0:0-1|snippet:(0)<>[#7]]", 'Current match');
is($match->inflate($index->dict)->to_string, '[0:0-1|snippet:[aa]]', 'Stringification');

TODO: {
  local $TODO = 'Check contexts'
};


done_testing;
__END__


ok($query->next, 'Next match');
is($index->dict->term_by_term_id(7), '*aa', 'Get term');
is($query->current_match->to_string, "[0:1-2|snippet:#9]", 'Current match');
ok($query->next, 'Next match');
is($index->dict->term_by_term_id(9), '*bb', 'Get term');
is($query->current_match->to_string, "[0:2-3|snippet:#7]", 'Current match');
ok($query->next, 'Next match');
is($query->current_match->to_string, "[0:3-4|snippet:#9]", 'Current match');
ok(!$query->next, 'No more match');

