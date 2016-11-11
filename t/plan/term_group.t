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
# is($query->plan_for($index)->to_string, '[der&art]', 'Planned Stringification');


$query = $qb->token(
  $qb->term_or('opennlp/c=NP', 'tt/p=NN')
);

ok(!$query->is_any, 'Isn\'t any');
ok(!$query->is_optional, 'Isn\'t optional');
ok(!$query->is_null, 'Isn\'t null');
ok(!$query->is_negative, 'Isn\'t negative');
ok(!$query->is_extended, 'Isn\'t extended');
is($query->to_string, '[opennlp/c=NP|tt/p=NN]', 'Stringification');
# is($query->plan_for($index)->to_string, '[der&art]', 'Planned Stringification');

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
# is($query->plan_for($index)->to_string, '[der&art]', 'Planned Stringification');

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
# is($query->plan_for($index)->to_string, '[der&art]', 'Planned Stringification');

diag 'Test further';

done_testing;

__END__
