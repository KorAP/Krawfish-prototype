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

$koral->query($qb->bool_or('aa', 'bb'));

$koral->compilation(
  $mb->enrich(
    $mb->e_snippet
  )
);

is($koral->to_string,
   "compilation=[enrich=[snippet=[hit]]],query=[aa|bb]",
   'Stringification');

ok(my $koral_query = $koral->to_query, 'Normalization');

# This is a query that is fine to be send to nodes
is($koral_query->to_string,
   "snippet(hit:filter(aa|bb,[1]))",
   'Stringification');

# This is a query that is fine to be send to segments:
ok($koral_query = $koral_query->identify($index->dict), 'Identify');

# This is a query that is fine to be send to nodes
is($koral_query->to_string(1),
   "snippet(hit:filter(#8|#10,[1]))",
   'Stringification');

ok(my $query = $koral_query->optimize($index->segment), 'Optimize');
is ($query->to_string, 'eSnippet(hit:filter(or(#10,#8),[1]))', 'Stringification');

ok($query->next, 'Next match');
is($query->current_match->inflate($index->dict)->to_string,
   "[0:0-1|snippet:[aa]]", 'Current match');

diag 'Retrieve snippets multiple times';

done_testing;
__END__

is($query->current_match->to_string(1), "[0:0-1|snippet:(0)<>[#7]]", 'Current match');
is($query->current_match->to_string(1), "[0:0-1|snippet:(0)<>[#7]]", 'Current match');


ok($query->next, 'Next match');
is($index->dict->term_by_term_id(7), SUBTERM_PREF . 'aa', 'Get term');
is($query->current_match->to_string(1), "[0:1-2|snippet:(0)< >[#9]]", 'Current match');
ok($query->next, 'Next match');
is($index->dict->term_by_term_id(9), SUBTERM_PREF . 'bb', 'Get term');
is($query->current_match->to_string(1), "[0:2-3|snippet:(0)< >[#7]]", 'Current match');
ok($query->next, 'Next match');
is($query->current_match->to_string(1), "[0:3-4|snippet:(0)< >[#9]]", 'Current match');
is($query->current_match->inflate($index->dict)->to_string,
   "[0:3-4|snippet:(0)< >['.bb']]",
   'Current match');
ok(!$query->next, 'No more match');


TODO: {
  local $TODO = 'Fix snippets to start at hit start (without preceding bytes)'
};



done_testing;
__END__


# Get facets object
ok(my $snippet = Krawfish::Compile::Segment::Enrich::Snippet->new(
  query => $prepare,
  index => $index
), 'Create count object');



done_testing;

__END__


