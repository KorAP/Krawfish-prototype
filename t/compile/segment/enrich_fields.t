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
  corpus => 'corpus-1',
  store_uri => 'My URL'
} => [qw/bb cc/], 'Add new document');


my $koral = Krawfish::Koral->new;
my $qb = $koral->query_builder;
my $mb = $koral->compile_builder;

$koral->query($qb->token('aa'));

$koral->compile(
  $mb->enrich(
    $mb->e_fields('license','corpus')
  )
);

is($koral->to_string,
   "compile=[enrich=[fields:['license','corpus']]],query=[[aa]]",
   'Stringification');

ok(my $koral_query = $koral->to_query, 'Normalization');

# This is a query that is fine to be send to nodes
is($koral_query->to_string,
   "fields('license','corpus':filter(aa,[1]))",
   'Stringification');

# This is a query that is fine to be send to segments:
ok($koral_query = $koral_query->identify($index->dict), 'Identify');

# This is a query that is fine to be send to nodes
is($koral_query->to_string(1),
   "fields(#1,#5:filter(#8,[1]))",
   'Stringification');

ok(my $fields = $koral_query->optimize($index->segment), 'optimize query');


ok($fields->next, 'Next');
is($fields->current->to_string, '[0:0-1]', 'Current object');

is($fields->current_match->to_string, "[0:0-1|fields:#1=#2,#5=#6]",
   'Current match');

ok($fields->next, 'Next');
is($fields->current_match->to_string, "[1:0-1|fields:#1=#11,#5=#13]",
   'Current match');
ok(!$fields->next, 'No more next');



# Fields for multiple spans
# Retrieve including stored data
$koral = Krawfish::Koral->new;
$koral->query($qb->bool_or('aa', 'bb'));
$koral->compile(
  $mb->enrich(
    $mb->e_fields('license','corpus', 'uri')
  )
);
$fields = $koral->to_query->identify($index->dict)->optimize($index->segment);


ok($fields->next, 'Next');
is($fields->current->to_string, '[0:0-1]', 'Current object');
is($fields->current_match->to_string, "[0:0-1|fields:#1=#2,#5=#6]",
   'Current match');

ok($fields->next, 'Next');
is($fields->current->to_string, '[0:1-2]', 'Current object');
is($fields->current_match->to_string, "[0:1-2|fields:#1=#2,#5=#6]",
   'Current match');

ok($fields->next, 'Next');
is($fields->current->to_string, '[1:0-1]', 'Current object');
is($fields->current_match->to_string, "[1:0-1|fields:#1=#11,#5=#13]",
   'Current match');

ok($fields->next, 'Next');
is($fields->current->to_string, '[1:1-2]', 'Current object');
is($fields->current_match->to_string, "[1:1-2|fields:#1=#11,#5=#13]",
   'Current match');

ok($fields->next, 'Next');
is($fields->current->to_string, '[2:0-1]', 'Current object');
is($fields->current_match->to_string, "[2:0-1|fields:#1=#14,#5=#6,#16='My URL']",
   'Current match');

ok(!$fields->next, 'Next');



done_testing;
__END__


