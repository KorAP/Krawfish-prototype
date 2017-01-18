use Test::More;
use Test::Krawfish;
use Data::Dumper;
use strict;
use warnings;

use_ok('Krawfish::Index');
use_ok('Krawfish::Koral::Corpus::Builder');
use_ok('Krawfish::Result::Group');
use_ok('Krawfish::Result::Group::Fields');

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
ok(my $query = $cb->field_or(
  $cb->string('author')->eq('Peter'),
  $cb->string('age')->eq('7')
), 'Create corpus query');

is($query->to_string, 'author=Peter|age=7', 'Stringification');
ok(!$query->is_negative, 'Check negativity');

# Create class criterion
my $criterion = Krawfish::Result::Group::Fields->new(
  $index,
  ['author']
);

is($criterion->to_string, 'fields[author]', 'Stringification');

# Create group
my $group = Krawfish::Result::Group->new(
  $query->prepare_for($index),
  $criterion
);

is($group->to_string, "groupBy(fields[author]:or('author:Peter','age:7'))", 'Stringification');

ok($group->next, 'Go to next');

is_deeply($group->current_group, {
  'author' => 'Peter',
  freq => 3,
  doc_freq => 3
}, 'Correct classes');

ok($group->next, 'Go to next');

is_deeply($group->current_group, {
  'author' => 'Michael',
  freq => 1,
  doc_freq => 1
}, 'Correct classes');

ok(!$group->next, 'No more next');

done_testing;
__END__
