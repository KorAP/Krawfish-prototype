use strict;
use warnings;
use Test::More;
use Test::Krawfish;

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

ok($plan = $plan->optimize($index), 'Optimizing');
is($plan->to_string, "and([1],'author:Peter')", 'Stringification');

# matches($plan, [qw/[0] [1] [2]/]);

# ok($index->live->delete(1), 'Document deleted directly');



done_testing;
__END__
