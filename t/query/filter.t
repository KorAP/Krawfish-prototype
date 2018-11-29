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
   "or(or(filter(or(or(#10,#8),#6),#2),constr(pos=2:#6,filter(#8,#2))),rep(2-2:filter(#6,#2)))",
   'Stringification');


# Query filter with corpus classes
ok($corpus = $cb->bool_or(
  $cb->class($cb->string('id')->eq(1),2),
  $cb->class($cb->string('genre')->eq('novel'),3)
), 'Create corpus query');
ok($term = $qb->term('aa'), 'Create term query');
ok($query = $qb->filter_by($term, $corpus), 'Filter by corpus');
ok($query_plan = $query->normalize->finalize->identify($index->dict)->optimize($index->segment), 'Create query plan');
is($query_plan->to_string, "filter(#6,or(class(2:#4),class(3:#2)))", 'Stringification');
is($query_plan->max_freq, 5, 'max freq');
matches($query_plan, ['[0:0-1!2,3]','[0:2-3!2,3]','[2:0-1!3]'], '3 matches');


# Query filter with corpus classes
ok($corpus = $cb->bool_or(
  $cb->class($cb->string('id')->eq(1),2),
  $cb->class($cb->string('genre')->eq('novel'),3)
), 'Create corpus query');

# aa (bb?|{2:cc})
ok($term = $qb->seq(
  $qb->term('aa'),
  $qb->bool_or(
    $qb->repeat(
      $qb->term('bb'),
      0,
      1
    ),
    $qb->class(
      $qb->term('cc'),
      2)
  )
), 'Create term query');

ok($query = $qb->filter_by($term, $corpus), 'Filter by corpus');
ok($query_plan = $query->normalize, 'Normalize');

# aa (bb|{2:cc})?
is($query_plan->to_string, "filter(aa((bb)|({2:cc}))?,{2:id=1}|{3:genre=novel})", 'Stringification');

# aa (bb|{2:cc})?
ok($query_plan = $query_plan->finalize, 'Finalization');
is($query_plan->to_string, "filter(aa((bb)|({2:cc}))?,{2:id=1}|{3:genre=novel})", 'Stringification');

# aa | aa (bb|{2:cc})
ok($query_plan = $query_plan->identify($index->dict)->optimize($index->segment), 'Optimize');
is($query_plan->to_string, "or(filter(#6,or(class(2:#4),class(3:#2))),constr(pos=2048:or(#8,class(2:#10)),filter(#6,or(class(2:#4),class(3:#2)))))", 'Stringification');

# In this example, the filter is not applied to all operands,
# e.g. constr(
#        pos=2048:
#        or(#8,class(2:#10)), <- !
#        filter(
#          #6,
#          or(
#            class(2:#4),
#            class(3:#2)
#          )
#        )
#      )

# id=1 -> 0; novel -> 0,2
# aa (bb|cc) -> 0:0-1, 0:0-2, 0:2-3, 2:0-1, 2:0-2
is($query_plan->max_freq, 10, 'max freq');
ok($query_plan->next, 'Move to next');
is($query_plan->current->to_string, '[0:0-1!2,3]', 'Match');
ok($query_plan->next, 'Move to next');
is($query_plan->current->to_string, '[0:0-2!2,3]', 'Match');
ok($query_plan->next, 'Move to next');
is($query_plan->current->to_string, '[0:2-3!2,3]', 'Match');
ok($query_plan->next, 'Move to next');
is($query_plan->current->to_string, '[0:2-4!2,3]', 'Match');
ok($query_plan->next, 'Move to next');
is($query_plan->current->to_string, '[2:0-1!3]', 'Match');
ok($query_plan->next, 'Move to next');
is($query_plan->current->to_string, '[2:0-2!3$0,2,1,2]', 'Match');
ok(!$query_plan->next, 'Move to next');




done_testing;
