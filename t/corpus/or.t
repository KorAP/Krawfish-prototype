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

is($query->to_string, 'id=3|id=2', 'Stringification');

ok(my $plan = $query->plan_for($index), 'Planning');

is($plan->to_string, "or('id:3','id:2')", 'Stringification');

ok($plan->next, 'Init vc');
is($plan->current->to_string, '[0]', 'First doc');
ok($plan->next, 'Next doc');
is($plan->current->to_string, '[1]', 'First doc');
ok(!$plan->next, 'No more next doc');

diag 'Test further';

done_testing;
__END__
