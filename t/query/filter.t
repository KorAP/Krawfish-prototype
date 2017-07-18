use Test::More;
use Test::Krawfish;
use strict;
use warnings;

use_ok('Krawfish::Koral::Corpus::Builder');
use_ok('Krawfish::Koral::Query::Builder');
use_ok('Krawfish::Query::Filter');
use_ok('Krawfish::Index');

my $index = Krawfish::Index->new;
ok_index($index, {
  id => 1,
  genre => 'novel',
} => [qw/aa bb aa bb cc bb aa/], 'Add complex document');
ok_index($index, {
  id => 2,
  genre => 'news',
} => [qw/aa bb aa bb cc bb aa/], 'Add complex document');
ok_index($index, {
  id => 3,
  genre => 'novel',
} => [qw/aa bb aa bb cc bb aa/], 'Add complex document');

ok(my $cb = Krawfish::Koral::Corpus::Builder->new, 'Create CorpusBuilder');

ok(my $corpus = $cb->string('genre')->eq('novel'), 'Create corpus query');
ok(my $corpus_plan = $corpus->normalize->finalize->optimize($index), 'Plan');

ok(my $qb = Krawfish::Koral::Query::Builder->new, 'Create CorpusBuilder');
ok(my $term = $qb->term('aa'), 'Create term query');
ok(my $term_plan = $term->normalize->finalize->optimize($index), 'Create query plan');

ok(my $filter = Krawfish::Query::Filter->new(
  $term_plan,
  $corpus_plan
), 'Build filter');

is($filter->freq, 6, 'Get frequency');

done_testing;
