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
} => [qw/aa bb aa bb cc/], 'Add complex document');
ok_index($index, {
  id => 2,
  genre => 'news',
} => [qw/aa bb aa/], 'Add complex document');
ok_index($index, {
  id => 3,
  genre => 'novel',
} => [qw/aa cc/], 'Add complex document');

ok(my $cb = Krawfish::Koral::Corpus::Builder->new, 'Create CorpusBuilder');
ok(my $qb = Krawfish::Koral::Query::Builder->new, 'Create CorpusBuilder');



ok(my $corpus = $cb->string('genre')->eq('novel'), 'Create corpus query');

ok(my $term = $qb->term('aa'), 'Create term query');

ok(my $query = $qb->filter_by($term, $corpus), 'Filter by corpus');

ok(my $query_plan = $query->normalize->finalize->identify($index->dict)->optimize($index->segment), 'Create query plan');
is($query_plan->to_string, "filter(#6,#2)", 'Stringification');
is($query_plan->max_freq, 5, 'max freq');
matches($query_plan, [qw/[0:0-1] [0:2-3] [2:0-1]/], '3 matches');


# Query filter with separate corpora
ok($term = $qb->bool_or(
  $qb->term('cc'),
  $qb->term('aa')
), 'Create new term query');
ok($query = $qb->filter_by($term, $corpus), 'Filter by corpus');

ok($query_plan = $query->normalize->finalize->identify($index->dict)->optimize($index->segment), 'Create query plan');
is($query_plan->to_string, "filter(or(#10,#6),#2)", 'Stringification');

matches($query_plan, [qw/[0:0-1] [0:2-3] [0:4-5] [2:0-1] [2:1-2]/], '5 matches');


# Check filter optimization
# On filtering level
ok($term = $qb->bool_or(
  $qb->term('aa'),
  $qb->term('bb'),
  $qb->bool_or(
    $qb->term('cc'),
    $qb->term('bb')
  )
), 'Create new term query');
ok($query = $qb->filter_by($term, $corpus), 'Filter by corpus');
is($query->to_string, "filter(aa|bb|(bb|cc),genre=novel)", 'Stringification');
ok($query_plan = $query->normalize->finalize->identify($index->dict)->optimize($index->segment), 'Create query plan');

# Non-complex queries are filtered only once
is($query_plan->to_string, "filter(or(or(#10,#8),#6),#2)", 'Stringification');


# Check filter optimization
# On optimization level
ok($term = $qb->bool_or(
  $qb->term('cc'),
  $qb->seq(
    $qb->term('aa'),
    $qb->term('aa'),
  ),
  $qb->term('bb'),
  $qb->seq(
    $qb->term('aa'),
    $qb->term('bb'),
  ),
  $qb->term('aa'),
), 'Create new term query');
ok($query = $qb->filter_by($term, $corpus), 'Filter by corpus');

# Order here is just alphabetical
is($query->to_string, "filter((aa)|(aaaa)|(aabb)|(bb)|(cc),genre=novel)", 'Stringification');
ok($query_plan = $query->normalize->finalize->identify($index->dict)->optimize($index->segment), 'Create query plan');

# Non-complex queries are grouped, so filtering is done only once
is($query_plan->to_string,
   "or(or(filter(or(or(#10,#8),#6),#2),constr(pos=2:#6,filter(#8,#2))),constr(pos=2:#6,filter(#6,#2)))",
   'Stringification');




done_testing;
