use Test::More;
use Test::Krawfish;
use strict;
use warnings;

use_ok('Krawfish::Index');
use_ok('Krawfish::Koral::Query::Builder');
use_ok('Krawfish::Result::Snippet');

my $index = Krawfish::Index->new;
ok_index($index, {
  docID => 'doc-1',
  license => 'free',
  corpus => 'corpus-2'
} => [qw/aa bb aa bb/], 'Add new document');

my $kq = Krawfish::Koral::Query::Builder->new;
my $query = $kq->term_or('aa', 'bb');

is($query->to_string, 'aa|bb', 'Stringification');

my $prepare = $query->normalize->finalize->optimize($index);

is($prepare->to_string, "or('aa','bb')", 'Stringification');

# Get facets object
ok(my $snippet = Krawfish::Result::Snippet->new(
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

TODO: {
  local $TODO = 'Test further - with matches'
};


done_testing;

__END__


