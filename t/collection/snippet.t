use Test::More;
use Test::Krawfish;
use strict;
use warnings;

use_ok('Krawfish::Index');
use_ok('Krawfish::Koral::Query::Builder');
use_ok('Krawfish::Collection::Snippet');

my $index = Krawfish::Index->new;
ok_index($index, {
  docID => 'doc-1',
  license => 'free',
  corpus => 'corpus-2'
} => \'aa bb aa bb' => [qw/aa bb aa bb/], 'Add new document');

my $kq = Krawfish::Koral::Query::Builder->new;
my $query = $kq->term_or('aa', 'bb');

is($query->to_string, 'aa|bb', 'Stringification');

my $prepare = $query->prepare_for($index);

is($prepare->to_string, "or('aa','bb')", 'Stringification');

# Get facets object
ok(my $snippet = Krawfish::Collection::Snippet->new(
  $prepare,
  $index
), 'Create count object');

ok($snippet->next, 'Next match');
is($snippet->current_match->to_string, "[0:0-1=snippet='aa bb aa bb']", 'Current match');
ok($snippet->next, 'Next match');
is($snippet->current_match->to_string, "[0:1-2=snippet='aa bb aa bb']", 'Current match');
ok($snippet->next, 'Next match');
is($snippet->current_match->to_string, "[0:2-3=snippet='aa bb aa bb']", 'Current match');
ok($snippet->next, 'Next match');
is($snippet->current_match->to_string, "[0:3-4=snippet='aa bb aa bb']", 'Current match');
ok(!$snippet->next, 'No more match');

diag 'Test further - with matches';

done_testing;

__END__


