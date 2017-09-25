use strict;
use warnings;
use utf8;
use Krawfish::Util::Constants qw/:PREFIX/;
use Test::More;
use Test::Krawfish;
use Data::Dumper;

use_ok('Krawfish::Koral::Document');
use_ok('Krawfish::Koral');
use_ok('Krawfish::Index');


# Add some data
ok(my $doc = Krawfish::Koral::Document->new(
  't/data/doc3-segments.jsonld'
), 'Load document');

ok(my $index = Krawfish::Index->new, 'Create new index');

# Transform dictionary to term_id stream
ok($doc = $doc->identify($index->dict), 'Translate to term identifiers');

# Add document to segment
my $doc_id = $index->segment->add($doc);
is($doc_id, 0, 'Doc id well added');

# Get objects for querying
my $koral = Krawfish::Koral->new;
my $qb = $koral->query_builder;
my $query;

# Check data by query retrieval
# Search for <akron/c=NP>
$koral->query($qb->span('akron/c=NP'));
ok($query = $koral->to_query->identify($index->dict)->optimize($index->segment),
   'Materialize');
is($query->to_string, 'filter(#11,[1])', 'Stringification');
matches($query, [qw/[0:0-3] [0:4-8]/], 'Search');


# Search for akron=Bau-Leiter
$koral->query($qb->token('akron=Bau-Leiter'));
ok($query = $koral->to_query->identify($index->dict)->optimize($index->segment),
   'Materialize');
is($query->to_string, 'filter(#14,[1])', 'Stringification');
matches($query, [qw/[0:1-3]/], 'Search');

# Search for position(startsWith|endsWith:<akron/c=NP>,akron=Bau-Leiter)
$koral->query(
  $qb->position(
    [qw/endsWith startsWith/],
    $qb->span('akron/c=NP'),
    $qb->token('akron=Bau-Leiter')
  )
);
ok($query = $koral->to_query->identify($index->dict)->optimize($index->segment),
   'Create query');
is($query->to_string, 'constr(pos=272:#11,filter(#14,[1]))', 'Stringification');
matches($query, [qw/[0:0-3]/], 'Search');


###
# Create forward pointer
###
ok(my $fwd = $index->segment->forward->pointer, 'Get pointer');

ok(defined $fwd->skip_doc(0), 'Skip to first document');
is($fwd->doc_id, 0, 'Skip to first document');

ok($fwd->next, 'Go to first subtoken');
is($fwd->pos, 0, 'First subtoken');
is($fwd->current->term_id, 8, 'Get term id');
is($fwd->current->term_id, 8, 'Get term id');

is($fwd->current->preceding_data, '', 'Get term id');
is($index->dict->term_by_term_id(8), SUBTERM_PREF . 'Der', 'Get term by term id');

ok($fwd->next, 'Go to first subtoken');
is($fwd->pos, 1, 'Second subtoken');
is($fwd->current->term_id, 13, 'Get term id');
is($fwd->current->term_id, 13, 'Get term id');
is($fwd->current->preceding_data, ' ', 'Get term id');
is($index->dict->term_by_term_id(13), SUBTERM_PREF . 'Bau', 'Get term by term id');

ok($fwd->next, 'Go to first subtoken');
is($fwd->pos, 2, 'Third subtoken');
is($fwd->current->term_id, 15, 'Get term id');
is($fwd->current->preceding_data, '-', 'Get term id');
is($index->dict->term_by_term_id(15), SUBTERM_PREF . 'Leiter', 'Get term by term id');

ok($fwd->prev, 'Go to first subtoken');
is($fwd->pos, 1, 'Second subtoken');
is($fwd->current->term_id, 13, 'Get term id');
is($fwd->current->term_id, 13, 'Get term id');
is($fwd->current->preceding_data, ' ', 'Get term id');
is($index->dict->term_by_term_id(13), SUBTERM_PREF . 'Bau', 'Get term by term id');

ok(my @anno = $fwd->current->annotations, 'Get annotations');
is($anno[0]->[0], 14, 'Annotation');
is($index->dict->term_by_term_id($anno[0]->[0]),
   TOKEN_PREF . 'akron=Bau-Leiter', 'Annotation');

ok($fwd = $index->segment->forward->pointer, 'Get pointer');
ok(defined $fwd->skip_doc(0), 'Skip to first document');
ok(defined $fwd->skip_pos(2), 'Skip to second subtoken');
is($fwd->doc_id, 0, 'Skip to first document');
is($fwd->pos, 2, 'Third subtoken');
is($fwd->current->term_id, 15, 'Get term id');
is($fwd->current->preceding_data, '-', 'Get term id');
my $dict = $index->dict;
is($dict->term_by_term_id(15), SUBTERM_PREF . 'Leiter', 'Get term by term id');

ok($fwd->next, 'Skip to next token');

my $foundry_id = $dict->term_id_by_term(FOUNDRY_PREF . 'opennlp');
my $layer_id = $dict->term_id_by_term(LAYER_PREF . 'p');
my $anno_id = $dict->term_id_by_term(TOKEN_PREF . 'opennlp/p=V');

is_deeply($fwd->current->annotation(
  $foundry_id,
  $layer_id,
  $anno_id
), [[4]], 'Get data for annotation');

ok($fwd->prev, 'Move to previous item');

is_deeply($fwd->current->annotation(
  $foundry_id,
  $layer_id,
  $anno_id
),[], 'Get data for non-existing annotation');

ok($fwd->next, 'Move to previous item');

is_deeply($fwd->current->annotation(
  $foundry_id,
  $layer_id,
  $anno_id
), [[4]], 'Get data for annotation');


done_testing;
__END__
