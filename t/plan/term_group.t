use Test::More;
use strict;
use warnings;
use Data::Dumper;

use_ok('Krawfish::Koral');
use_ok('Krawfish::Index');

my $index = Krawfish::Index->new;

ok(defined $index->add('t/data/doc1.jsonld'), 'Add new document');

my $koral = Krawfish::Koral->new;

my $qb = $koral->query_builder;

my $query = $qb->token(
  $qb->term_and('der', 'art')
);

ok(!$query->is_any, 'Isn\'t any');
ok(!$query->is_optional, 'Isn\'t optional');
ok(!$query->is_null, 'Isn\'t null');
ok(!$query->is_negative, 'Isn\'t negative');
ok(!$query->is_extended, 'Isn\'t extended');
is($query->to_string, '[der&art]', 'Stringification');
is($query->plan_for($index)->to_string, "pos(32:'der','art')", 'Planned Stringification');

$query = $qb->token(
  $qb->term_or('opennlp/c=NP', 'tt/p=NN')
);

ok(!$query->is_any, 'Isn\'t any');
ok(!$query->is_optional, 'Isn\'t optional');
ok(!$query->is_null, 'Isn\'t null');
ok(!$query->is_negative, 'Isn\'t negative');
ok(!$query->is_extended, 'Isn\'t extended');
is($query->to_string, '[opennlp/c=NP|tt/p=NN]', 'Stringification');
is($query->plan_for($index)->to_string, "or('opennlp/c=NP','tt/p=NN')", 'Planned Stringification');

$query = $qb->token(
  $qb->term_or(
    $qb->term_and('first', 'second'),
    $qb->term_and('third', 'fourth'),
  )
);

ok(!$query->is_any, 'Isn\'t any');
ok(!$query->is_optional, 'Isn\'t optional');
ok(!$query->is_null, 'Isn\'t null');
ok(!$query->is_negative, 'Isn\'t negative');
ok(!$query->is_extended, 'Isn\'t extended');
is($query->to_string, '[(first&second)|(third&fourth)]', 'Stringification');
is($query->plan_for($index)->to_string,
   "or(pos(32:'first','second'),pos(32:'third','fourth'))",
   'Planned Stringification');

$query = $qb->token(
  $qb->term_or(
    $qb->term_and('first', 'second'),
    $qb->term_and(
      'third',
      $qb->term_or('fourth', 'fifth')
    ),
    'sixth'
  )
);

ok(!$query->is_any, 'Isn\'t any');
ok(!$query->is_optional, 'Isn\'t optional');
ok(!$query->is_null, 'Isn\'t null');
ok(!$query->is_negative, 'Isn\'t negative');
ok(!$query->is_extended, 'Isn\'t extended');
is($query->to_string, '[(first&second)|(third&(fourth|fifth))|sixth]', 'Stringification');
is($query->plan_for($index)->to_string,
   "or(or(pos(32:'first','second'),pos(32:'third',or('fourth','fifth'))),'sixth')",
   'Planned Stringification');

$query = $qb->token(
  $qb->term_and('first', $qb->null)
);
is($query->to_string, '[first&0]', 'Stringifications');
is($query->plan_for($index)->to_string,
   "'first'",
   'Planned stringification');

# [first&opennlp/c!=NN]
$query = $qb->token(
  $qb->term_and('first', 'opennlp/c!=NN')
);
is($query->to_string, '[first&opennlp/c!=NN]', 'Stringifications');
is($query->plan_for($index)->to_string,
   "excl(32:'first','opennlp/c=NN')",
   'Planned Stringification');

# [first&opennlp/c!=NN&second&third&tt/p!=ADJA]
$query = $qb->token(
  $qb->term_and(
    $qb->term_and('first', 'opennlp/c!=NN'),
    $qb->term_and('second', 'tt/p!=ADJA')
  )
);
is($query->to_string, '[(first&opennlp/c!=NN)&(second&tt/p!=ADJA)]', 'Stringifications');
is($query->plan_for($index)->to_string,
   "excl(32:pos(32:'first','second'),or('opennlp/c=NN','tt/p=ADJA'))",
   'Planned Stringification');

done_testing;
__END__

