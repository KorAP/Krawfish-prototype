use Test::More;
use Test::Krawfish;
use strict;
use warnings;

# TODO:
#   Check with optional or null operand!
#   aa* and [] means it matches anywhere!

use_ok('Krawfish::Koral::Corpus::Builder');
use_ok('Krawfish::Koral::Query::Builder');
use_ok('Krawfish::Index');

my $index = Krawfish::Index->new;
ok_index($index, {
  integer_id => 2,
  author => 'Michael',
  genre => 'novel',
  integer_age => 4
} => [qw/aa bb cc dd/], 'Add complex document');

ok_index($index, {
  integer_id => 3,
  author => 'Peter',
  genre => 'novel',
  integer_age => 3
} => [qw/aa aa bb cc dd bb cc/], 'Add complex document');

ok_index($index, {
  integer_id => 5,
  author => 'Peter',
  genre => 'newsletter',
  integer_age => 4
} => [qw/aa bb cc dd bb/], 'Add complex document');

ok_index($index, {
  integer_id => 6,
  author => 'Michael',
  genre => 'newsletter',
  integer_age => 7
} => [qw/aa bb aa bb/], 'Add complex document');


ok(my $cb = Krawfish::Koral::Corpus::Builder->new, 'Create CorpusBuilder');
ok(my $qb = Krawfish::Koral::Query::Builder->new, 'Create QueryBuilder');

# Search in documents containing the sequence [bb][cc]
ok(my $query = $cb->bool_and(
  $cb->string('author')->eq('Peter'),
  $cb->span(
    $qb->seq(
      $qb->token('bb'),
      $qb->token('cc')
    )
  )
), 'Create corpus query');

is($query->to_string, 'span([bb][cc])&author=Peter', 'Stringification');
ok($query = $query->normalize, 'Normalize');
is($query->to_string, 'span(bbcc)&author=Peter', 'Stringification');
ok($query = $query->identify($index->dict), 'Identify');
is($query->to_string(1), '#17&span(#12#14)', 'Stringification');
ok($query = $query->optimize($index->segment), 'Optimize');
is($query->to_string, 'and(span(constr(pos=2:#12,#14)),#17)', 'Stringification');

# [1][2]
ok($query->next, 'Move to first item');
is($query->current->to_string, '[1]', 'Current doc');
ok($query->next, 'Move to first item');
is($query->current->to_string, '[2]', 'Current doc');
ok(!$query->next, 'No more documents');




# Search in documents containing the sequence [aa][bb]
ok($query = $cb->span(
  $qb->seq(
    $qb->token('aa'),
    $qb->token('bb')
  )
), 'Create corpus query');

is($query->to_string, 'span([aa][bb])', 'Stringification');
ok($query = $query->normalize, 'Normalize');
is($query->to_string, 'span(aabb)', 'Stringification');
ok($query = $query->identify($index->dict), 'Identify');
is($query->to_string(1), 'span(#10#12)', 'Stringification');
ok($query = $query->optimize($index->segment), 'Optimize');
is($query->to_string, 'span(constr(pos=2048:#12,#10))', 'Stringification');

matches($query, [qw/[0] [1] [2] [3]/]);


# Search in documents containing an optional span
ok($query = $cb->bool_and(
  $cb->string('author')->eq('Peter'),
  $cb->span(
    $qb->repeat(
      $qb->token('aa'), 0, 100
    )
  )
), 'Create corpus query');

# Ignore optionality
is($query->to_string, 'span([aa]{0,100})&author=Peter', 'Stringification');
ok($query = $query->normalize->identify($index->dict)->optimize($index->segment), 'Optimize');
is($query->to_string, '#17', 'Stringification');
matches($query, [qw/[1] [2]/]);


# Search in documents containing an non-optional span
ok($query = $cb->bool_and(
  $cb->string('author')->eq('Peter'),
  $cb->span(
    $qb->repeat(
      $qb->token('aa'), 1, 100
    )
  )
), 'Create corpus query');

is($query->to_string, 'span([aa]{1,100})&author=Peter', 'Stringification');
ok($query = $query->normalize->identify($index->dict)->optimize($index->segment), 'Optimize');
is($query->to_string, 'and(span(rep(1-100:#10)),#17)', 'Stringification');
matches($query, [qw/[1] [2]/]);


# Search in documents with non-existing span
ok($query = $cb->bool_and(
  $cb->string('author')->eq('Peter'),
  $cb->span(
    $qb->token('zz')
  )
), 'Create corpus query');

is($query->to_string, 'span([zz])&author=Peter', 'Stringification');
ok($query = $query->normalize->identify($index->dict)->optimize($index->segment), 'Optimize');
is($query->to_string, '[0]', 'Stringification');


# Search in documents with an alternative span
ok($query = $cb->bool_or(
  $cb->string('author')->eq('Michael'),
  $cb->span(
    $qb->seq(
      $qb->token('dd'), $qb->token('bb')
    )
  )
), 'Create corpus query');

is($query->to_string, 'span([dd][bb])|author=Michael', 'Stringification');
ok($query = $query->normalize->identify($index->dict)->optimize($index->segment), 'Optimize');
is($query->to_string, 'or(#2,span(constr(pos=2048:#12,#16)))', 'Stringification');
matches($query, [qw/[0] [1] [2] [3]/]);


# Search in documents with neglectable classes
ok($query = $cb->bool_or(
  $cb->string('author')->eq('Michael'),
  $cb->span(
    $qb->class(
      $qb->seq(
        $qb->class($qb->token('dd'),2),
        $qb->class($qb->token('bb'),3)
      ),
      1
    )
  )
), 'Create corpus query');

is($query->to_string, 'span({1:{2:[dd]}{3:[bb]}})|author=Michael', 'Stringification');
ok($query = $query->normalize, 'Normalize');
is($query->to_string, 'span(ddbb)|author=Michael', 'Stringification');
ok($query = $query->identify($index->dict)->optimize($index->segment), 'Optimize');
is($query->to_string, 'or(#2,span(constr(pos=2048:#12,#16)))', 'Stringification');
matches($query, [qw/[0] [1] [2] [3]/]);


done_testing;
__END__
