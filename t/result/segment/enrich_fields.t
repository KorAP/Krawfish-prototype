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
} => [qw/aa bb/], 'Add new document');
ok_index($index, {
  id => 'doc-2',
  license => 'closed',
  corpus => 'corpus-3'
} => [qw/aa bb/], 'Add new document');
ok_index($index, {
  id => 'doc-3',
  license => 'free',
  corpus => 'corpus-1'
} => [qw/bb cc/], 'Add new document');


my $koral = Krawfish::Koral->new;
my $qb = $koral->query_builder;
my $mb = $koral->meta_builder;

$koral->query($qb->token('aa'));

$koral->meta(
  $mb->enrich(
    $mb->e_fields('license, corpus')
  )
);

is($koral->to_string,
   "meta=[enrich=[fields:['license, corpus']]],query=[[aa]]",
   'Stringification');

ok(my $koral_query = $koral->to_query, 'Normalization');

# This is a query that is fine to be send to nodes
is($koral_query->to_string,
   "enrich(fields:['license, corpus','id']:sort(field='id'<;sortFilter:filter(aa,[1])))",
   'Stringification');

# This is a query that is fine to be send to segments:
ok($koral_query = $koral_query->identify($index->dict), 'Identify');


# This is a query that is fine to be send to nodes
is($koral_query->to_string,
   "enrich(fields:[#4]:sort(field=#4<;sortFilter:filter(#7,[1])))",
   'Stringification');

diag 'check field enrichments!';



done_testing;
__END__


# Get fields object
ok(my $fields = Krawfish::Result::Segment::Enrich::Fields->new(
  $index,
  $query->normalize->finalize->optimize($index),
  [qw/license corpus/]
), 'Create count object');

ok($fields->next, 'Next');
is($fields->current->to_string, '[0:0-1]', 'Current object');
is($fields->current_match->to_string, "[0:0-1|corpus='corpus-2';license='free']",
   'Current match');
ok($fields->next, 'Next');
is($fields->current_match->to_string, "[1:0-1|corpus='corpus-3';license='closed']",
   'Current match');
ok(!$fields->next, 'No more next');


# Fields for multiple spans
$query = $kq->bool_or('aa', 'bb');


# Get fields object
ok($fields = Krawfish::Result::Segment::Enrich::Fields->new(
  $index,
  $query->normalize->finalize->optimize($index),
  [qw/license corpus/]
), 'Create count object');

ok($fields->next, 'Next');
is($fields->current->to_string, '[0:0-1]', 'Current object');
is($fields->current_match->to_string, "[0:0-1|corpus='corpus-2';license='free']",
   'Current match');

ok($fields->next, 'Next');
is($fields->current->to_string, '[0:1-2]', 'Current object');
is($fields->current_match->to_string, "[0:1-2|corpus='corpus-2';license='free']",
   'Current match');

ok($fields->next, 'Next');
is($fields->current->to_string, '[1:0-1]', 'Current object');
is($fields->current_match->to_string, "[1:0-1|corpus='corpus-3';license='closed']",
   'Current match');

ok($fields->next, 'Next');
is($fields->current->to_string, '[1:1-2]', 'Current object');
is($fields->current_match->to_string, "[1:1-2|corpus='corpus-3';license='closed']",
   'Current match');

ok($fields->next, 'Next');
is($fields->current->to_string, '[2:0-1]', 'Current object');
is($fields->current_match->to_string, "[2:0-1|corpus='corpus-1';license='free']",
   'Current match');

ok(!$fields->next, 'Next');

done_testing;
__END__


