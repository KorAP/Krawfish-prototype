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
  date_pubDate => '2014-01-13'
} => [qw/aa bb/], 'Add complex document');
ok_index($index, {
  id => 5,
  author => 'David',
  date_pubDate => '2014-02-12'
} => [qw/aa bb/], 'Add complex document');


ok(my $cb = Krawfish::Koral::Corpus::Builder->new, 'Create CorpusBuilder');

ok(my $field = $cb->date('pubDate')->eq('2014-01-13'), 'String field');
is($field->to_string, "pubDate=2014-01-13", 'Stringification');
ok(my $plan = $field->normalize, 'Finalize');
is($plan->to_string, "pubDate=2014-01-13", 'Stringification');
ok($plan = $plan->finalize, 'Finalize');
is($plan->to_string, "[1]&pubDate=2014-01-13", 'Stringification');
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


TODO: {
  local $TODO = 'Test further'
};

done_testing;
__END__
