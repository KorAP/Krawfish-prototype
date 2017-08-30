use Test::More;
use Test::Krawfish;
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
my $mb = $koral->meta_builder;

$koral->query($qb->bool_or('aa', 'bb'));

$koral->meta(
  $mb->enrich(
    $mb->e_snippet
      )
);

is($koral->to_string,
   "meta=[enrich=[snippet]],query=[aa|bb]",
   'Stringification');

ok(my $koral_query = $koral->to_query, 'Normalization');

# This is a query that is fine to be send to nodes
is($koral_query->to_string,
   "snippet(?:filter(aa|bb,[1]))",
   'Stringification');

# This is a query that is fine to be send to segments:
ok($koral_query = $koral_query->identify($index->dict), 'Identify');

# This is a query that is fine to be send to nodes
is($koral_query->to_string,
   "snippet(?:filter(#10|#8,[1]))",
   'Stringification');

ok(my $query = $koral_query->optimize($index->segment), 'Optimize');
is ($query->to_string, 'snippet(filter(or(#10,#8),[1]))', 'Stringification');

ok($query->next, 'Next match');
is($query->current_match->to_string, "[0:0-1|snippet:#7]", 'Current match');
ok($query->next, 'Next match');
is($index->dict->term_by_term_id(7), '*aa', 'Get term');
is($query->current_match->to_string, "[0:1-2|snippet:#9]", 'Current match');
ok($query->next, 'Next match');
is($index->dict->term_by_term_id(9), '*bb', 'Get term');
is($query->current_match->to_string, "[0:2-3|snippet:#7]", 'Current match');
ok($query->next, 'Next match');
is($query->current_match->to_string, "[0:3-4|snippet:#9]", 'Current match');
ok(!$query->next, 'No more match');


TODO: {
  local $TODO = 'Test further - with matches'
};



done_testing;
__END__


# Get facets object
ok(my $snippet = Krawfish::Result::Segment::Enrich::Snippet->new(
  query => $prepare,
  index => $index
), 'Create count object');



done_testing;

__END__


