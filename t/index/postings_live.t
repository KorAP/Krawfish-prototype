use strict;
use warnings;
use Test::More;
use Test::Krawfish;
use Krawfish::Index::PostingsLive;


ok(my $lives = Krawfish::Index::PostingsLive->new(), 'Get live list');
is($lives->freq, 0, 'Get freq');

# Just fake some documents by level up the next_doc_id value
ok($lives->next_doc_id(10), 'Set last document');
is($lives->next_doc_id, 10, 'Get last document');
is($lives->freq, 10, 'Get freq');

ok(!$lives->delete(7,3,4), 'Delete three documents in wrong order');
ok($lives->delete(3, 4, 7), 'Delete three documents');
is($lives->freq, 7, 'Get freq');

# Get one pointer
ok(my $p1 = $lives->pointer, 'Get pointer');
is($p1->freq, 7, 'Get freq');
is($p1->to_string, '[1]', 'Stringify');

is($p1->doc_id, -1, 'Get doc_id');
ok($p1->next, 'Next');

is($p1->doc_id, 0, 'Get doc_id');
ok($p1->next, 'Next');
is($p1->doc_id, 1, 'Get doc_id');
ok($p1->next, 'Next');
is($p1->doc_id, 2, 'Get doc_id');
ok($p1->next, 'Next');
is($p1->doc_id, 5, 'Get doc_id');

ok($p1->next, 'Next');
is($p1->doc_id, 6, 'Get doc_id');
is($p1->to_config_string, '0,1,2,!3,!4,5,<6>,![7],8,9', 'Configuration');

ok($p1->next, 'Next');
is($p1->doc_id, 8, 'Get doc_id');
is($p1->to_config_string, '0,1,2,!3,!4,5,6,!7,<8>,9', 'Configuration');
ok($p1->next, 'Next');
is($p1->doc_id, 9, 'Get doc_id');
ok(!$p1->next, 'Next');
is($p1->doc_id, 10, 'Get doc_id');
ok(!$p1->next, 'Next');
is($p1->doc_id, 10, 'Get doc_id');
ok(!$p1->next, 'Next');
is($p1->doc_id, 10, 'Get doc_id');

# Get one pointer
ok(my $p2 = $lives->pointer, 'Get pointer');
is($p2->freq, 7, 'Get freq');
is($p2->to_string, '[1]', 'Stringify');

is($p2->skip_doc(3), 5, 'Skipped to 3');

is($p2->doc_id, 5, 'Get doc_id');
is($p2->skip_doc(6), 6, 'Skipped to 6');
is($p2->doc_id, 6, 'Get doc_id');
is($p2->skip_doc(9), 9, 'Skipped to 9');
is($p2->doc_id, 9, 'Get doc_id');

ok(!$p2->skip_doc(10), 'Skipped to 9');
is($p2->doc_id, 10, 'Get doc_id');
ok(!$p2->skip_doc(11), 'Skipped to 9');
is($p2->doc_id, 10, 'Get doc_id');
ok(!$p2->skip_doc(12), 'Skipped to 9');
is($p2->doc_id, 10, 'Get doc_id');


# Test with real index

use_ok('Krawfish::Index');
use_ok('Krawfish::Koral::Corpus::Builder');

ok(my $index = Krawfish::Index->new, 'New index');
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

ok(my $query = $cb->string('author')->eq('Peter'), 'Create corpus query');
is($query->to_string, 'author=Peter', 'Stringification');

ok(my $plan = $query->normalize->finalize, 'Planning');
is($plan->to_string, '[1]&author=Peter', 'Stringification');

ok($plan = $plan->identify($index->dict), 'Add identification');

ok(my $fin = $plan->optimize($index->segment), 'Optimizing');
is($fin->to_string, "and([1],#4)", 'Stringification');

matches($fin, [qw/[0] [1] [2]/]);

ok($index->segment->live->delete(1), 'Document deleted directly');
ok($fin = $plan->optimize($index->segment), 'Optimizing');
matches($fin, [qw/[0] [2]/]);



# Test with different order
ok($query = $cb->bool_or(
  $cb->bool_and(
    $cb->string('genre')->eq('newsletter'),
    $cb->anywhere
  ),
  $cb->bool_and(
    $cb->string('age')->eq('4'),
    $cb->anywhere
  )
), 'Create corpus query');

is($query->to_string, '([1]&age=4)|([1]&genre=newsletter)', 'Stringification');

ok($plan = $query->identify($index->dict)->optimize($index->segment), 'Planning');

is($plan->to_string, 'or(and([1],#15),and([1],#2))', 'Stringification');
matches($plan, [qw/[0] [2] [3]/], 'Test matches');



ok($query = $cb->bool_or(
  $cb->bool_and(
    $cb->string('author')->eq('Michael'),
    $cb->anywhere
  ),
  $cb->bool_and(
    $cb->string('genre')->eq('newsletter'),
    $cb->anywhere
  ),
  $cb->bool_and(
    $cb->string('age')->eq('4'),
    $cb->anywhere
  )
), 'Create corpus query');

is($query->to_string, '([1]&age=4)|([1]&author=Michael)|([1]&genre=newsletter)',
   'Stringification');

ok($plan = $query->identify($index->dict)->optimize($index->segment), 'Planning');

is($plan->to_string, 'or(or(and([1],#18),and([1],#15)),and([1],#2))', 'Stringification');
matches($plan, [qw/[0] [2] [3]/], 'Test matches');




done_testing;
__END__

