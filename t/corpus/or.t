use Test::More;
use Test::Krawfish;
use strict;
use warnings;

use_ok('Krawfish::Koral::Corpus::Builder');
use_ok('Krawfish::Index');

my $index = Krawfish::Index->new;
ok_index($index, {id => 2} => [qw/aa bb/], 'Add complex document');
ok_index($index, {id => 3} => [qw/aa bb/], 'Add complex document');
ok_index($index, {id => 5} => [qw/aa bb/], 'Add complex document');

ok(my $cb = Krawfish::Koral::Corpus::Builder->new, 'Create CorpusBuilder');

ok(my $query = $cb->field_or(
  $cb->string('id')->eq('3'),
  $cb->string('id')->eq('2')
), 'Create corpus query');

ok(!$query->has_classes, 'Has no classes');
is($query->to_string, 'id=2|id=3', 'Stringification');

ok(my $plan = $query->normalize->optimize($index), 'Planning');

is($plan->to_string, "or('id:2','id:3')", 'Stringification');

ok($plan->next, 'Init vc');
is($plan->current->to_string, '[0]', 'First doc');
ok($plan->next, 'Next doc');
is($plan->current->to_string, '[1]', 'First doc');
ok(!$plan->next, 'No more next doc');


ok_index($index, {id => 7} => [qw/aa bb/], 'Add complex document');
ok_index($index, {id => 9} => [qw/aa bb/], 'Add complex document');

ok($query = $cb->field_or(
  $cb->string('id')->eq('3'),
  $cb->string('id')->eq('2'),
  $cb->string('id')->eq('9')
), 'Create corpus query');

is($query->to_string, 'id=2|id=3|id=9', 'Stringification');

ok($plan = $query->normalize->optimize($index), 'Planning');

is($plan->to_string, "or(or('id:2','id:3'),'id:9')", 'Stringification');

matches($plan, [qw/[0] [1] [4]/], 'Matches');

# Indexed 2,3,5,7,9
ok($query = $cb->field_or(
  $cb->string('id')->ne('2'),
  $cb->string('id')->eq('5')
), 'Create corpus query');

is($query->to_string, 'id!=2|id=5', 'Stringification');
ok($plan = $query->normalize->finalize->optimize($index), 'Planning');
is($plan->to_string, "and(or(andNot([1],'id:2'),'id:5'),[1])", 'Stringification');

# matches($plan, [qw/[0] [1] [2] [3] [4]/], 'Matches');


diag 'Test further';

# Especially:
# - First operand is negative, second is positive
# - First operands have freq=0, first valid is negative


done_testing;
__END__
