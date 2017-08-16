use Test::More;
use Test::Krawfish;
use strict;
use warnings;

use_ok('Krawfish::Koral::Corpus::Builder');
use_ok('Krawfish::Index');

my $index = Krawfish::Index->new;
ok_index_2($index, {
  integer_id => 2,
  author => 'Peter',
  genre => 'novel',
  integer_age => 4
} => [qw/aa bb/], 'Add complex document');
ok_index_2($index, {
  integer_id => 3,
  author => 'Peter',
  genre => 'novel',
  integer_age => 3
} => [qw/aa bb/], 'Add complex document');
ok_index_2($index, {
  integer_id => 5,
  author => 'Peter',
  genre => 'newsletter',
  integer_age => 4
} => [qw/aa bb/], 'Add complex document');
ok_index_2($index, {
  integer_id => 6,
  author => 'Michael',
  genre => 'newsletter',
  integer_age => 7
} => [qw/aa bb/], 'Add complex document');

ok(my $cb = Krawfish::Koral::Corpus::Builder->new, 'Create CorpusBuilder');

ok(my $query = $cb->bool_and(
  $cb->string('author')->eq('Peter'),
  $cb->string('age')->eq('4')
), 'Create corpus query');

is($query->to_string, 'age=4&author=Peter', 'Stringification');
ok(!$query->is_negative, 'Check negativity');

ok(my $plan = $query->normalize->identify($index->dict)->optimize($index->segment), 'Planning');

is($plan->to_string, "and(#2,#6)", 'Stringification');

ok($plan->next, 'Init vc');
is($plan->current->to_string, '[0]', 'First doc');
ok($plan->next, 'More next');
is($plan->current->to_string, '[2]', 'First doc');
ok(!$plan->next, 'No more next');

# Complex virtual corpus
ok($query = $cb->bool_or(
  $cb->bool_and(
    $cb->string('author')->eq('Peter'),
    $cb->string('age')->eq(3)
  ),
  $cb->string('id')->eq(2)
), 'Create corpus query');

is($query->to_string, '(age=3&author=Peter)|id=2', 'Stringification');
ok(!$query->is_negative, 'Check negativity');

ok($plan = $query->normalize->identify($index->dict)->optimize($index->segment), 'Planning');

is($plan->to_string, "or(#8,and(#2,#13))", 'Stringification');

ok($plan->next, 'Init vc');
is($plan->current->to_string, '[0]', 'First doc');
ok($plan->next, 'More next');
is($plan->current->to_string, '[1]', 'First doc');
ok(!$plan->next, 'No more next');

# Complex virtual corpus with negation
ok($query = $cb->bool_and(
  $cb->string('author')->eq('Peter'),
  $cb->string('age')->ne(4)
),
, 'Create corpus query');


is($query->to_string, 'age!=4&author=Peter', 'Stringification');
ok(!$query->is_negative, 'Check negativity');

ok(my $norm = $query->normalize, 'Plan logically');
is($norm->to_string, "(author=Peter&!age=4)", 'Stringification');

ok(my $opt = $norm->identify($index->dict)->optimize($index->segment), 'Planning');
is($opt->to_string, "andNot(#2,#6)", 'Stringification');


ok($opt->next, 'Init vc');
is($opt->current->to_string, '[1]', 'First doc');
ok(!$opt->next, 'No more next');


# Complex virtual corpus with negation
ok($query = $cb->bool_and(
  $cb->string('author')->ne('Peter'),
  $cb->string('age')->ne(4)
),
, 'Create corpus query');

is($query->to_string, 'age!=4&author!=Peter', 'Stringification');
ok(!$query->is_negative, 'Check negativity');


# Plan a query and finalize it
ok($plan = $query->normalize, 'Planning');
is($plan->to_string, "!(age=4|author=Peter)", 'Stringification');
ok($plan = $plan->finalize, 'Planning');
is($plan->to_string, "([1]&!(age=4|author=Peter))", 'Stringification');
ok($plan = $plan->identify($index->dict)->optimize($index->segment), 'Optimizing');
is($plan->to_string, "andNot([1],or(#6,#2))", 'Stringification');

ok($plan->next, 'More next');
is($plan->current->to_string, '[3]', 'First doc');
ok(!$plan->next, 'No more next');


done_testing;
__END__






# Complex virtual corpus with negation
ok($query = $cb->bool_and(
  $cb->string('genre')->eq('novel'),
  $cb->string('author')->ne('Peter'),
  $cb->string('age')->ne(4)
),
, 'Create corpus query');

ok(!$query->has_classes, 'Contains classes');

is($query->to_string, 'age!=4&author!=Peter&genre=novel', 'Stringification');
ok(!$query->is_negative, 'Check negativity');
ok($plan = $query->plan_for($index), 'Planning');
is($plan->to_string, "without('genre:novel',or('age:4','author:Peter'))",
   'Stringification');

diag 'Test further';

# Especially:
# - First operand is negative, second is positive
#   etc.
# - First operands have freq=0, first valid is negative


done_testing;
__END__
