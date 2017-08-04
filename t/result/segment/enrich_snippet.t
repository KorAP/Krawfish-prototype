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
  $mb->snippet
);

is($koral->to_string,
   "meta=[snippet],query=[aa|bb]",
   'Stringification');

ok(my $koral_query = $koral->to_query, 'Normalization');

# This is a query that is fine to be send to nodes
is($koral_query->to_string,
   "snippet(?:fields('id':sort(field='id'<;sortFilter:filter(aa|bb,[1]))))",
   'Stringification');

# This is a query that is fine to be send to segments:
ok($koral_query = $koral_query->identify($index->dict), 'Identify');

# This is a query that is fine to be send to nodes
is($koral_query->to_string,
   "snippet(?:fields(#4:sort(field=#4<;sortFilter:filter(#7|#8,[1]))))",
   'Stringification');

TODO: {
  local $TODO = 'Test further - with matches'
};



done_testing;
__END__

is($query->to_string, 'aa|bb', 'Stringification');

my $prepare = $query->normalize->finalize->optimize($index);

is($prepare->to_string, "or('aa','bb')", 'Stringification');

# Get facets object
ok(my $snippet = Krawfish::Result::Segment::Enrich::Snippet->new(
  query => $prepare,
  index => $index
), 'Create count object');

ok($snippet->next, 'Next match');
is($snippet->current_match->to_string, "[0:0-1|snippet='aa bb aa bb']", 'Current match');
ok($snippet->next, 'Next match');
is($snippet->current_match->to_string, "[0:1-2|snippet='aa bb aa bb']", 'Current match');
ok($snippet->next, 'Next match');
is($snippet->current_match->to_string, "[0:2-3|snippet='aa bb aa bb']", 'Current match');
ok($snippet->next, 'Next match');
is($snippet->current_match->to_string, "[0:3-4|snippet='aa bb aa bb']", 'Current match');
ok(!$snippet->next, 'No more match');


done_testing;

__END__


