use Test::More;
use strict;
use warnings;
use Test::Krawfish;
use Data::Dumper;

use_ok('Krawfish::Koral');

my $koral = Krawfish::Koral->new;
ok(my $qb = $koral->query_builder, 'Create QueryBuilder');

my $query = $qb->in_corpus($qb->token('machen'),1);

is($query->to_string, 'inCorpus(1:[machen])', 'Stringification');
ok($query = $query->normalize, 'Normalize');
ok(!$query->is_anywhere, 'Anywhere');
ok(!$query->is_optional, 'Not optional');
ok(!$query->is_null, 'Not null');
ok(!$query->is_negative, 'Not negative');
ok(!$query->is_extended, 'Not extendeed');
ok(!$query->is_extended_right, 'Not extended to the right');
ok(!$query->is_extended_left, 'Not extended to the left');
is($query->min_span, 1, 'Minimum span');
is($query->max_span, 1, 'Maximum span');


$query = $qb->in_corpus(
  $qb->seq(
    $qb->token('das'),
    $qb->repeat(
      $qb->token('machen'),
      0,2
    )
  ),
  1
);

is($query->to_string, 'inCorpus(1:[das][machen]{0,2})', 'Stringification');
ok($query = $query->normalize, 'Normalize');
ok(!$query->is_anywhere, 'Anywhere');
ok(!$query->is_optional, 'Not optional');
ok(!$query->is_null, 'Not null');
ok(!$query->is_negative, 'Not negative');
ok(!$query->is_extended, 'Not extendeed');
ok(!$query->is_extended_right, 'Not extended to the right');
ok(!$query->is_extended_left, 'Not extended to the left');
is($query->min_span, 1, 'Minimum span');
is($query->max_span, 3, 'Maximum span');

ok(my $cb = $koral->corpus_builder, 'Create CorpusBuilder');

# Create compile
$koral->corpus(
  $cb->bool_or(
    $cb->class($cb->string('lang')->eq('de'), 1),
    $cb->class($cb->string('lang')->eq('en'), 2)
  )
);

$koral->query(
  $qb->seq(
    $qb->token('opennlp/p=DET'),
    $qb->bool_or(
      $qb->in_corpus($qb->token('machen'),1),
      $qb->in_corpus($qb->token('make'),2)
    )
  )
);

# TODO:
#   Check if all classes referenced are in the
#   corpus query.

is($koral->to_query->to_string,
   'filter(opennlp/p=DET(inCorpus(1:machen))|(inCorpus(2:make)),{1:lang=de}|{2:lang=en})',
   'Stringification');



done_testing;
__END__

