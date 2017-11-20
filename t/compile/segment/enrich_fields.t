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
my $qb = $koral->query_builder;
my $mb = $koral->compilation_builder;

$koral->query($qb->token('aa'));

$koral->compilation(
  $mb->enrich(
    $mb->e_fields('license','corpus')
  )
);

is($koral->to_string,
   "compilation=[enrich=[fields:['license','corpus']]],query=[[aa]]",
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
   "fields(#1,#7:filter(#10,[1]))",
   'Stringification');

ok(my $fields = $koral_query->optimize($index->segment), 'optimize query');


ok($fields->next, 'Next');
is($fields->current->to_string, '[0:0-1]', 'Current object');

is($fields->current_match->to_string, "[0:0-1|fields:#1=#2,#7=#8]",
   'Current match');

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
is($fields->current_match->to_string,
   "[0:1-2|fields:'corpus'='corpus-2','year'=1996,'license'='free']",
   'Current match');

ok($fields->next, 'Next');
is($fields->current->to_string, '[1:0-1]', 'Current object');
is($fields->current_match->to_string(1), "[1:0-1|fields:#1=#13,#5=#15(1998),#7=#16]",
   'Current match');

ok($fields->next, 'Next');
is($fields->current->to_string, '[1:1-2]', 'Current object');
is($fields->current_match->to_string(1), "[1:1-2|fields:#1=#13,#5=#15(1998),#7=#16]",
   'Current match');

ok($fields->next, 'Next');
is($fields->current->to_string, '[2:0-1]', 'Current object');
is($fields->current_match->to_string(1), "[2:0-1|fields:#1=#17,#5=#19(2002),#7=#8,#20='My URL']",
   'Current match');

ok(!$fields->next, 'Next');




$koral = Krawfish::Koral->new;
$koral->query($qb->token('aa'));
$koral->compilation(
  $mb->enrich(
    $mb->e_fields('license','corpus')
  )
);

my $result = $koral->to_query
  ->identify($index->dict)
  ->optimize($index->segment)
  ->compile
  ->inflate($index->dict);

ok($kq = $result->to_koral_query, 'Serialize KQ');

my $first_fields = $kq->{matches}->[0]->{fields};
is($first_fields->[0]->{key}, 'corpus');
is($first_fields->[0]->{value}, 'corpus-2');
is($first_fields->[1]->{key}, 'license');
is($first_fields->[1]->{value}, 'free');

done_testing;
__END__


