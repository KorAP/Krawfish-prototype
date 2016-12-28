use Test::More;
use Test::Krawfish;
use strict;
use warnings;

use_ok('Krawfish::Koral::Corpus::Builder');
use_ok('Krawfish::Index');

my $index = Krawfish::Index->new;
ok_index($index, {
  id => 2,
  author => 'Peter',
  genre => 'novel',
  age => 4
} => [qw/aa bb/], 'Add complex document');
ok_index($index, {
  id => 3,
  author => 'Peter',
  genre => 'novel',
  age => 3
} => [qw/aa bb/], 'Add complex document');
ok_index($index, {
  id => 5,
  author => 'Peter',
  genre => 'newsletter',
  age => 4
} => [qw/aa bb/], 'Add complex document');
ok_index($index, {
  id => 6,
  author => 'Michael',
  genre => 'newsletter',
  age => 7
} => [qw/aa bb/], 'Add complex document');

ok(my $cb = Krawfish::Koral::Corpus::Builder->new, 'Create CorpusBuilder');

ok(my $query = $cb->field_and(
  $cb->string('author')->eq('Peter'),
  $cb->string('age')->eq('4')
), 'Create corpus query');

is($query->to_string, 'author=Peter&age=4', 'Stringification');
ok(!$query->is_negative, 'Check negativity');

ok(my $plan = $query->plan_for($index), 'Planning');

is($plan->to_string, "and('author:Peter','age:4')", 'Stringification');

ok($plan->next, 'Init vc');
is($plan->current->to_string, '[0]', 'First doc');
ok($plan->next, 'More next');
is($plan->current->to_string, '[2]', 'First doc');
ok(!$plan->next, 'No more next');

# Complex virtual corpus
ok($query = $cb->field_or(
  $cb->field_and(
    $cb->string('author')->eq('Peter'),
    $cb->string('age')->eq(3)
  ),
  $cb->string('id')->eq(2)
), 'Create corpus query');

is($query->to_string, '(author=Peter&age=3)|id=2', 'Stringification');
ok(!$query->is_negative, 'Check negativity');

ok($plan = $query->plan_for($index), 'Planning');

is($plan->to_string, "or(and('author:Peter','age:3'),'id:2')", 'Stringification');

ok($plan->next, 'Init vc');
is($plan->current->to_string, '[0]', 'First doc');
ok($plan->next, 'More next');
is($plan->current->to_string, '[1]', 'First doc');
ok(!$plan->next, 'No more next');

# Complex virtual corpus with negation
ok($query = $cb->field_and(
  $cb->string('author')->eq('Peter'),
  $cb->string('age')->ne(4)
),
, 'Create corpus query');

is($query->to_string, 'author=Peter&age!=4', 'Stringification');
ok(!$query->is_negative, 'Check negativity');

ok($plan = $query->plan_for($index), 'Planning');
is($plan->to_string, "without('author:Peter','age:4')", 'Stringification');

ok($plan->next, 'Init vc');
is($plan->current->to_string, '[1]', 'First doc');
ok(!$plan->next, 'No more next');


# Complex virtual corpus with negation
ok($query = $cb->field_and(
  $cb->string('author')->ne('Peter'),
  $cb->string('age')->ne(4)
),
, 'Create corpus query');

is($query->to_string, 'author!=Peter&age!=4', 'Stringification');
ok($query->is_negative, 'Check negativity');
ok($plan = $query->plan_for($index), 'Planning');
is($plan->to_string, "not(or('author:Peter','age:4'))", 'Stringification');

ok($plan->next, 'More next');
is($plan->current->to_string, '[3]', 'First doc');
ok(!$plan->next, 'No more next');

# Complex virtual corpus with negation
ok($query = $cb->field_and(
  $cb->string('genre')->eq('novel'),
  $cb->string('author')->ne('Peter'),
  $cb->string('age')->ne(4)
),
, 'Create corpus query');

is($query->to_string, 'genre=novel&author!=Peter&age!=4', 'Stringification');
ok(!$query->is_negative, 'Check negativity');
ok($plan = $query->plan_for($index), 'Planning');
is($plan->to_string, "without(without('genre:novel','author:Peter'),'age:4')",
   'Stringification');


done_testing;
__END__
