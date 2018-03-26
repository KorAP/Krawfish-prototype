use Test::More;
use Test::Krawfish;
use strict;
use warnings;

use_ok('Krawfish::Koral::Corpus::Builder');
use_ok('Krawfish::Index');

my $index = Krawfish::Index->new;

ok_index_file($index, 'doc2.jsonld', 'Add new document');
ok_index_file($index, 'doc1.jsonld', 'Add new document');
ok_index_file($index, 'doc3-segments.jsonld', 'Add new document');



ok(my $cb = Krawfish::Koral::Corpus::Builder->new, 'Create CorpusBuilder');

ok(my $field = $cb->string('license')->eq('free'), 'String field');
is($field->to_string, "license=free", 'Stringification');


ok(my $plan = $field->normalize, 'Normalize');
is($plan->to_string, "license=free", 'Stringification');
ok($plan = $plan->finalize, 'Finalize');
is($plan->to_string, "[1]&license=free", 'Stringification');
ok($plan = $plan->identify($index->dict), 'Identify');
#is($plan->to_string, "#38&[1]", 'Stringification');
ok($plan = $plan->optimize($index->segment), 'Optimize');
#is($plan->to_string, "and([1],#38)", 'Stringification');
ok(!$plan->current, 'No current');
ok($plan->next, 'Next posting');
is($plan->current->to_string, '[1]', 'Current doc id');
ok(!$plan->next, 'No next posting');
ok(!$plan->current, 'No Current doc id');


ok($field = $cb->string('license')->eq('closed'), 'String field');
is($field->to_string, "license=closed", 'Stringification');
ok(!$field->is_negative, 'Negative');
ok($plan = $field->normalize->finalize->identify($index->dict)->optimize($index->segment), 'Plan');
# is($plan->to_string, "and([1],#6)", 'Stringification');
ok(!$plan->current, 'No current');
ok($plan->next, 'Next posting');
is($plan->current->to_string, '[0]', 'Current doc id');
ok($plan->next, 'Next posting');
is($plan->current->to_string, '[2]', 'Current doc id');
ok(!$plan->next, 'No next posting');
ok(!$plan->current, 'No Current doc id');


ok($field = $cb->string('license')->ne('closed'), 'String field');
is($field->to_string, "license!=closed", 'Stringification');
ok($field->is_negative, 'Negative');
ok($plan = $field->normalize->finalize->identify($index->dict)->optimize($index->segment), 'Plan');
# is($plan->to_string, "andNot([1],#6)", 'Stringification');
ok(!$plan->current, 'No current');
ok($plan->next, 'Next posting');
is($plan->current->to_string, '[1]', 'Current doc id');
ok(!$plan->next, 'No next posting');
ok(!$plan->current, 'No Current doc id');

TODO: {
  local $TODO = 'Test further'
};

done_testing;
__END__
