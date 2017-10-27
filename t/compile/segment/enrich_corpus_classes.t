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
  corpus => 'corpus-2',
  integer_year => 1996
} => [qw/aa bb/], 'Add new document');
ok_index($index, {
  id => 'doc-2',
  license => 'closed',
  corpus => 'corpus-3',
  integer_year => 1998
} => [qw/aa bb/], 'Add new document');
ok_index($index, {
  id => 'doc-3',
  license => 'free',
  corpus => 'corpus-1',
  store_uri => 'My URL',
  integer_year => 2002
} => [qw/bb cc/], 'Add new document');


my $koral = Krawfish::Koral->new;
my $cb = $koral->corpus_builder;
my $qb = $koral->query_builder;
my $mb = $koral->compilation_builder;

# Define corpus
$koral->corpus(
  $cb->bool_or(
    $cb->class($cb->string('license')->eq('free'), 1),
    $cb->class($cb->span(
      $qb->term('aa')
    ), 2)
  )
);

# Define query
$koral->query(
  $qb->token('bb')
);

# Define compilation
$koral->compilation(
  $mb->enrich(
    $mb->e_corpus_classes(1,2),
    $mb->e_fields("corpus")
  )
);

is($koral->to_string,
   "compilation=[enrich=[corpusclasses:[1,2],".
     "fields:['corpus']]],".
     "corpus=[{1:license=free}|{2:span(aa)}],".
     "query=[[bb]]",
   'Stringification');

ok(my $koral_query = $koral->to_query, 'Normalization');

# This is a query that is fine to be send to nodes
is($koral_query->to_string,
   "corpusclasses(1,2:fields('corpus':filter(bb,{1:license=free}|{2:span(aa)})))",
   'Stringification');

# This is a query that is fine to be send to segments:
ok($koral_query = $koral_query->identify($index->dict), 'Identify');

# This is a query that is fine to be send to nodes
is($koral_query->to_string(1),
   'corpusclasses(1,2:fields(#1:filter(#12,{1:#8}|{2:span(#10)})))',
   'Stringification');

ok(my $query = $koral_query->optimize($index->segment), 'optimize query');

# This is a query that is fine to be send to nodes
is($query->to_string(1),
   'corpusClasses(24576:enrichFields(1:filter(#12,or(class(1:#8),class(2:span(#10))))))',
   'Stringification');

ok($query->next, 'Next');
is($query->current->to_string, '[0:1-2!1,2]', 'Current object');
is($query->current_match->to_string, "[0:1-2!1,2|fields:#1=#2|inCorpus:1,2]",
   'Current match');

ok($query->next, 'Next');
is($query->current->to_string, '[1:1-2!2]', 'Current object');
is($query->current_match->to_string, "[1:1-2!2|fields:#1=#13|inCorpus:2]",
   'Current match');

ok($query->next, 'Next');
is($query->current->to_string, '[2:0-1!1]', 'Current object');
is($query->current_match->to_string, "[2:0-1!1|fields:#1=#17|inCorpus:1]",
   'Current match');
ok(!$query->next, 'Next');

done_testing;
__END__










my $kq = $fields->current_match->inflate($index->dict)->to_koral_fragment;
is($kq->{'@type'}, 'koral:match', 'KQ');
is($kq->{fields}->[0]->{key}, 'corpus', 'KQ');
is($kq->{fields}->[0]->{value}, 'corpus-2', 'KQ');
is($kq->{fields}->[1]->{key}, 'license', 'KQ');
is($kq->{fields}->[1]->{value}, 'free', 'KQ');

ok($fields->next, 'Next');
is($fields->current_match->to_string, "[1:0-1|fields:#1=#13,#7=#16]",
   'Current match');

$kq = $fields->current_match->inflate($index->dict)->to_koral_fragment;
is($kq->{'@type'}, 'koral:match', 'KQ');
is($kq->{fields}->[0]->{key}, 'corpus', 'KQ');
is($kq->{fields}->[0]->{value}, 'corpus-3', 'KQ');
is($kq->{fields}->[1]->{key}, 'license', 'KQ');
is($kq->{fields}->[1]->{value}, 'closed', 'KQ');

ok(!$fields->next, 'No more next');



# Fields for multiple spans
# Retrieve including stored data
$koral = Krawfish::Koral->new;
$koral->query($qb->bool_or('aa', 'bb'));
$koral->compilation(
  $mb->enrich(
    $mb->e_fields('license','corpus', 'uri', 'year')
  )
);
$fields = $koral->to_query->identify($index->dict)->optimize($index->segment);

ok($fields->next, 'Next');
is($fields->current->to_string, '[0:0-1]', 'Current object');
is($fields->current_match->to_string, "[0:0-1|fields:#1=#2,#5=#6(1996),#7=#8]",
   'Current match');

$kq = $fields->current_match->inflate($index->dict)->to_koral_fragment;
is($kq->{'@type'}, 'koral:match', 'KQ');
is($kq->{fields}->[0]->{key}, 'corpus', 'KQ');
is($kq->{fields}->[0]->{value}, 'corpus-2', 'KQ');
is($kq->{fields}->[1]->{key}, 'year', 'KQ');
is($kq->{fields}->[1]->{value}, 1996, 'KQ');
is($kq->{fields}->[2]->{key}, 'license', 'KQ');
is($kq->{fields}->[2]->{value}, 'free', 'KQ');

ok($fields->next, 'Next');
is($fields->current->to_string, '[0:1-2]', 'Current object');
is($fields->current_match->to_string, "[0:1-2|fields:#1=#2,#5=#6(1996),#7=#8]",
   'Current match');

ok($fields->next, 'Next');
is($fields->current->to_string, '[1:0-1]', 'Current object');
is($fields->current_match->to_string, "[1:0-1|fields:#1=#13,#5=#15(1998),#7=#16]",
   'Current match');

ok($fields->next, 'Next');
is($fields->current->to_string, '[1:1-2]', 'Current object');
is($fields->current_match->to_string, "[1:1-2|fields:#1=#13,#5=#15(1998),#7=#16]",
   'Current match');

ok($fields->next, 'Next');
is($fields->current->to_string, '[2:0-1]', 'Current object');
is($fields->current_match->to_string, "[2:0-1|fields:#1=#17,#5=#19(2002),#7=#8,#20='My URL']",
   'Current match');

ok(!$fields->next, 'Next');



done_testing;
__END__


