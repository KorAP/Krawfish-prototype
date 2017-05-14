use Test::More;
use Test::Krawfish;
use strict;
use warnings;

use_ok('Krawfish::Koral::Corpus::Builder');
use_ok('Krawfish::Index');

my $index = Krawfish::Index->new;

ok(my $cb = Krawfish::Koral::Corpus::Builder->new, 'Create CorpusBuilder');
ok_index($index, {id => 2} => [qw/aa bb/], 'Add complex document');


# Check for idempotence

ok(my $query = $cb->field_or(
  $cb->string('id')->eq('2'),
  $cb->string('id')->eq('2')
), 'Create corpus query');

is($query->to_string, 'id=2|id=2', 'Stringification');

ok(my $plan = $query->plan_for($index), 'Idempotence');

is($plan->to_string, "'id:2'", 'Stringification');

ok($query = $cb->field_and(
  $cb->string('id')->eq('2'),
  $cb->string('id')->eq('2')
), 'Create corpus query');
is($query->to_string, 'id=2&id=2', 'Stringification');
ok($plan = $query->plan_for($index), 'Idempotence');
is($plan->to_string, "'id:2'", 'Stringification');


done_testing;
