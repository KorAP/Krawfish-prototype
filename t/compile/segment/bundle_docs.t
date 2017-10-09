use Test::More;
use Test::Krawfish;
use Data::Dumper;
use strict;
use warnings;

use_ok('Krawfish::Index');
use_ok('Krawfish::Koral');
use_ok('Krawfish::Compile::Segment::BundleDocs');

# Create some documents
my $index = Krawfish::Index->new;

ok_index($index, {
  id => 2,
  author => 'Peter',
  genre => 'novel',
  age => 4
} => [qw/aa bb bb aa/], 'Add complex document');
ok_index($index, {
  id => 3,
  author => 'Julian',
  genre => 'novel',
  age => 3
} => [qw/aa bb aa/], 'Add complex document');
ok_index($index, {
  id => 5,
  author => 'Abraham',
  genre => 'newsletter',
  title => 'Your way to success!',
  age => 4
} => [qw/aa bb aa/], 'Add complex document');

ok($index->commit, 'Commit data');

my $koral = Krawfish::Koral->new;
my $qb = $koral->query_builder;

$koral->query(
  $qb->bool_or(
    $qb->token('aa'),
    $qb->token('bb')
  )
);

ok(my $query = $koral->to_query->identify($index->dict)->optimize($index->segment),
   'Transform');

is($query->to_string, 'filter(or(#12,#10),[1])', 'Stringification');

ok($query = Krawfish::Compile::Segment::BundleDocs->new($query),
   'Bundle all matches in the same doc');

is($query->to_string, 'bundleDocs(filter(or(#12,#10),[1]))', 'Stringification');

ok($query->next_bundle, 'Move forward');

# is($query->current_match->doc_id, 0, 'Current match');
ok(my $bundle = $query->current_bundle, 'Get first bundle');

is($bundle->to_string, '[[0:0-1]|[0:1-2]|[0:2-3]|[0:3-4]]', 'Stringification');
ok($query->next_bundle, 'Move to next bundle');
# ok($query->next_bundle, 'Move to next bundle');

# TODO:
#   Respect next_doc!

ok($query->next_bundle, 'Move to next bundle');

#is($query->current_match->doc_id, 1, 'Current match');
#ok($query->preview_doc_id, 'Move to next document');
#is($query->current_match->doc_id, 2, 'Current match');
ok($bundle = $query->current_bundle, 'Get first bundle');
is($bundle->to_string, '[[2:0-1]|[2:1-2]|[2:2-3]]', 'Stringification');
ok(!$query->next_bundle, 'Move forward');


# Create new document
$index = Krawfish::Index->new;
ok_index($index, {
  id => 2,
} => [qw/aa bb/], 'Add complex document');
ok_index($index, {
  id => 3,
} => [qw/aa bb/], 'Add complex document');
ok_index($index, {
  id => 1,
} => [qw/aa bb aa/], 'Add complex document');
ok_index($index, {
  id => 6,
} => [qw/bb/], 'Add complex document');
ok_index($index, {
  id => 5,
} => [qw/aa bb/], 'Add complex document');

$koral->query(
  $qb->seq(
    $qb->token('aa'),
    $qb->token('bb')
  )
);

ok($query = $koral->to_query->identify($index->dict)->optimize($index->segment),
   'Transform');

ok($query = Krawfish::Compile::Segment::BundleDocs->new($query),
   'Bundle all matches in the same doc');

ok($query->next_bundle, 'Move forward');
is($query->current_bundle->to_string, '[[0:0-2]]', 'Current match');
ok($query->next_bundle, 'Move forward');
is($query->current_bundle->to_string, '[[1:0-2]]', 'Current match');
ok($query->next_bundle, 'Move forward');
is($query->current_bundle->to_string, '[[2:0-2]]', 'Current match');
ok($query->next_bundle, 'Move forward');
is($query->current_bundle->to_string, '[[4:0-2]]', 'Current match');
ok(!$query->next_bundle, 'Move forward');


# Again with unbundling
ok($query = $koral->to_query->identify($index->dict)->optimize($index->segment),
   'Transform');

ok($query = Krawfish::Compile::Segment::BundleDocs->new($query),
   'Bundle all matches in the same doc');

ok($query->next, 'Move forward');
is($query->current->to_string, '[0:0-2]', 'Current match');
ok($query->next, 'Move forward');
is($query->current->to_string, '[1:0-2]', 'Current match');
ok($query->next, 'Move forward');
is($query->current->to_string, '[2:0-2]', 'Current match');
ok($query->next, 'Move forward');
is($query->current->to_string, '[4:0-2]', 'Current match');
ok(!$query->next, 'Move forward');


done_testing;
