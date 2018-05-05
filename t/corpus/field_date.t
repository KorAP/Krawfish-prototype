use Test::More;
use Test::Krawfish;
use strict;
use warnings;

use_ok('Krawfish::Koral::Corpus::Builder');
use_ok('Krawfish::Index');

my $index = Krawfish::Index->new;

ok_index($index, {
  id => 2,
  author => 'David',
  date_pubDate => '2014-01-13'
} => [qw/aa bb/], 'Add complex document');
ok_index($index, {
  id => 3,
  author => 'Michael',
  date_pubDate => '2014-01-13--2014-01-17'
} => [qw/aa bb/], 'Add complex document');
ok_index($index, {
  id => 5,
  author => 'David',
  date_pubDate => '2014-02-12'
} => [qw/aa bb/], 'Add complex document');


ok(my $cb = Krawfish::Koral::Corpus::Builder->new, 'Create CorpusBuilder');

# eq is identically interpreted as 'intersect', as there are no 'eq' fields indexed
ok(my $field = $cb->date('pubDate')->eq('2014-01-13'), 'String field');
is($field->to_string, "pubDate=2014-01-13", 'Stringification');
ok(my $plan = $field->normalize, 'Finalize');
is($plan->to_string, "pubDate=2014-01-13", 'Stringification');
ok($plan = $plan->finalize, 'Finalize');
is($plan->to_string, "(pubDate=2014-01-13]|pubDate=2014-01]|pubDate=2014])&[1]", 'Stringification');
ok($plan = $plan->identify($index->dict), 'Identify');
# is($plan->to_string, "#4&[1]", 'Stringification');
ok($plan = $plan->optimize($index->segment), 'Optimize');
# is($plan->to_string, "and([1],#4)", 'Stringification');
ok(!$plan->current, 'No current');
ok($plan->next, 'Next posting');
is($plan->current->to_string, '[0]', 'Current doc id');
ok($plan->next, 'Next posting');
is($plan->current->to_string, '[1]', 'Current doc id');
ok(!$plan->next, 'No next posting');
ok(!$plan->current, 'No Current doc id');


ok($field = $cb->date('pubDate')->intersect('2014-01-16'), 'Create intersection range query');
is($field->to_string, "pubDate&=2014-01-16", 'Stringification');
ok($plan = $field->normalize, 'Normalize');
is($plan->to_string, 'pubDate=2014-01-16]|pubDate=2014-01]|pubDate=2014]', 'Stringification');
ok($plan = $plan->finalize, 'Finalize');
is($plan->to_string,
   '(pubDate=2014-01-16]|pubDate=2014-01]|pubDate=2014])&[1]',
   'Stringification');
ok($plan = $plan->identify($index->dict), 'Identify');
# is($plan->to_string, "#4&[1]", 'Stringification');
ok($plan = $plan->optimize($index->segment), 'Optimize');
# is($plan->to_string, "and([1],#4)", 'Stringification');
ok(!$plan->current, 'No current');
ok($plan->next, 'Next posting');
is($plan->current->to_string, '[1]', 'Current doc id');
ok(!$plan->next, 'No next posting');
ok(!$plan->current, 'No Current doc id');

ok_index($index, {
  id => 6,
  author => 'David',
  date_pubDate => '2014-01-12--2014-02-20'
} => [qw/aa bb/], 'Add complex document');


ok($field = $cb->date('pubDate')->intersect('2014-01-16','2014-01-19'),
   'Create intersection range query');
is($field->to_string, "pubDate&=[[2014-01-16--2014-01-19]]", 'Stringification');
ok($plan = $field->normalize, 'Normalize');
is($plan->to_string, 'pubDate=2014-01-16]|pubDate=2014-01-17]|pubDate=2014-01-18]|pubDate=2014-01-19]|pubDate=2014-01]|pubDate=2014]', 'Stringification');
ok($plan = $plan->finalize, 'Finalize');
is($plan->to_string,
   '(pubDate=2014-01-16]|pubDate=2014-01-17]|pubDate=2014-01-18]|pubDate=2014-01-19]|pubDate=2014-01]|pubDate=2014])&[1]',
   'Stringification');
ok($plan = $plan->identify($index->dict), 'Identify');
ok($plan = $plan->optimize($index->segment), 'Optimize');
ok(!$plan->current, 'No current');
ok($plan->next, 'Next posting');
is($plan->current->to_string, '[1]', 'Current doc id');
ok($plan->next, 'Next posting');
is($plan->current->to_string, '[3]', 'Current doc id');
ok(!$plan->next, 'No next posting');
ok(!$plan->current, 'No Current doc id');


TODO: {
  local $TODO = 'Test further'
};

done_testing;
__END__
