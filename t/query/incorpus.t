use Test::More;
use strict;
use warnings;
use Test::Krawfish;
use Data::Dumper;

use_ok('Krawfish::Koral');
use_ok('Krawfish::Index');

my $index = Krawfish::Index->new;
ok_index($index, {
  id => 1,
  lang => 'en'
} => '[opennlp/p=DET][make][opennlp/p=DET][machen]', 'Add complex document');
ok_index($index, {
  id => 2,
  lang => 'de'
} => '[opennlp/p=DET][make][opennlp/p=DET][machen]', 'Add complex document');
ok_index($index, {
  id => 3,
  lang => 'en'
} => '[opennlp/p=DET][machen][opennlp/p=DET][make]', 'Add complex document');

my $koral = Krawfish::Koral->new;
ok(my $cb = $koral->corpus_builder, 'Create CorpusBuilder');
ok(my $qb = $koral->query_builder, 'Create QueryBuilder');

# Create compile
$koral->corpus(
  $cb->bool_or(
    $cb->class($cb->string('lang')->eq('de'), 1),
    $cb->class($cb->string('lang')->eq('en'), 2),
    $cb->class($cb->string('id')->eq(3), 3),
  )
);

$koral->query(
  $qb->seq(
    $qb->token('opennlp/p=DET'),
    $qb->bool_or(
      $qb->in_corpus($qb->token('machen'),1),
      $qb->in_corpus($qb->token('make'),2, 3)
    )
  )
);

ok(my $query = $koral->to_query, 'Create query');

is($query->to_string,
   'filter(opennlp/p=DET(inCorpus(1:machen))|(inCorpus(2,3:make)),{1:lang=de}|{2:lang=en}|{3:id=3})',
   'Stringification'
 );

ok($query = $query->identify($index->dict)->optimize($index->segment), 'Inflate and optimize');

# The incorpus filter means that more filters are requies, which
# will probably slow down some queries.
is($query->to_string,
   'constr(pos=2:#6,or(inCorpus(1:filter(#12,or(or(class(1:#14),class(3:#15)),class(2:#4)))),inCorpus(2,3:filter(#10,or(or(class(1:#14),class(3:#15)),class(2:#4))))))',
   'Stringification');

ok($query->next, 'Next');
is($query->current->to_string, '[0:0-2!2]', 'Get current match');
ok($query->next, 'Next');
is($query->current->to_string, '[1:2-4!1]', 'Get current match');
ok($query->next, 'Next');
is($query->current->to_string, '[2:2-4!2,3]', 'Get current match');
ok(!$query->next, 'Next');


done_testing;
__END__

