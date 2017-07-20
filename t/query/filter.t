use Test::More;
use Test::Krawfish;
use strict;
use warnings;

use_ok('Krawfish::Koral::Corpus::Builder');
use_ok('Krawfish::Koral::Query::Builder');
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
ok(my $qb = Krawfish::Koral::Query::Builder->new, 'Create CorpusBuilder');

ok(my $corpus = $cb->string('genre')->eq('novel'), 'Create corpus query');

ok(my $term = $qb->term('aa'), 'Create term query');

ok(my $query = $qb->filter_by($term, $corpus), 'Filter by corpus');

ok(my $query_plan = $query->normalize->finalize->optimize($index), 'Create query plan');
is($query_plan->to_string, "filter('aa','genre:novel')", 'Stringification');
is($query_plan->max_freq, 9, '6 max freq');
matches($query_plan, [qw/[0:0-1] [0:2-3] [0:6-7] [2:0-1] [2:2-3] [2:6-7]/], '6 matches');


done_testing;
