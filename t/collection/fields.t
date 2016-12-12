use Test::More;
use Test::Krawfish;
use strict;
use warnings;

use_ok('Krawfish::Index');
use_ok('Krawfish::Koral::Query::Builder');
use_ok('Krawfish::Collection::Fields');

my $index = Krawfish::Index->new;
ok_index($index, {
  docID => 'doc-1',
  license => 'free',
  corpus => 'corpus-2'
} => [qw/aa bb/], 'Add new document');
ok_index($index, {
  docID => 'doc-2',
  license => 'closed',
  corpus => 'corpus-3'
} => [qw/aa bb/], 'Add new document');
ok_index($index, {
  docID => 'doc-3',
  license => 'free',
  corpus => 'corpus-1'
} => [qw/bb cc/], 'Add new document');

my $kq = Krawfish::Koral::Query::Builder->new;
my $query = $kq->token('aa');

# Get facets object
ok(my $fields = Krawfish::Collection::Fields->new(
  $query->prepare_for($index),
  $index,
  [qw/license corpus/]
), 'Create count object');

ok($fields->next, 'Next');
is($fields->current_match, "[0:0-1=corpus='corpus-2';docID='doc-1';license='free']",
   'Current match');
ok($fields->next, 'Next');
is($fields->current_match, "[1:0-1=corpus='corpus-3';docID='doc-2';license='closed']",
   'Current match');
ok(!$fields->next, 'No more next');

diag 'Test further with multiple fields';

done_testing;
__END__
