use Test::More;
use Test::Krawfish;
use Data::Dumper;
use strict;
use warnings;

use_ok('Krawfish::Index');
use_ok('Krawfish::Koral');

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


my $koral = Krawfish::Koral->new;
my $cb = $koral->corpus_builder;
my $mb = $koral->meta_builder;

# Corpus object
$koral->corpus(
  $cb->bool_or(
    $cb->string('author')->eq('Peter'),
    $cb->string('age')->eq('7')
  )
);

# Meta object
$koral->meta(
  $mb->group_by(
    $mb->g_fields('author')
  )
);

is($koral->corpus->to_string, 'age=7|author=Peter', 'Stringification');
ok(!$koral->corpus->is_negative, 'Check negativity');


is($koral->to_string,
   "meta=[group=[fields:['author']]],corpus=[age=7|author=Peter]",
   'Stringification');


ok(my $koral_query = $koral->to_query, 'Normalization');

# This is a query that is fine to be send to nodes
is($koral_query->to_string,
   "group(fields:['author']:[1]&(age=7|author=Peter))",
   'Stringification');


# This is a query that is fine to be send to segments:
ok($koral_query = $koral_query->identify($index->dict),
   'Identify');

# This is a query that is fine to be send to nodes
#is($koral_query->to_string,
#   "group(fields:[#3]:(#17|#4)&[1])",
#   'Stringification');

diag 'check group fields!';


done_testing;
__END__



# Create class criterion
my $criterion = Krawfish::Result::Group::Fields->new(
  $index,
  ['author']
);

is($criterion->to_string, 'fields[author]', 'Stringification');





# Create group
my $group = Krawfish::Result::Group->new(
  $query->normalize->optimize($index),
  $criterion
);


is($group->to_string, "groupBy(fields[author]:or('age:7','author:Peter'))", 'Stringification');

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
