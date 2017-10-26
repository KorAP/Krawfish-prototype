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
  age => 3
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
my $mb = $koral->compilation_builder;
my $qb = $koral->query_builder;

# Corpus object
$koral->corpus(
  $cb->bool_or(
    $cb->string('author')->eq('Peter'),
    $cb->string('age')->eq('7')
  )
);

# Compile object
$koral->compilation(
  $mb->group_by(
    $mb->g_fields('author')
  )
);

is($koral->corpus->to_string, 'age=7|author=Peter', 'Stringification');
ok(!$koral->corpus->is_negative, 'Check negativity');


is($koral->to_string,
   "compilation=[group=[fields:['author']]],corpus=[age=7|author=Peter]",
   'Stringification');


ok(my $koral_query = $koral->to_query, 'Normalization');

# This is a query that is fine to be send to nodes
is($koral_query->to_string,
   "gFields('author':[1]&(age=7|author=Peter))",
   'Stringification');


# This is a query that is fine to be send to segments:
ok($koral_query = $koral_query->identify($index->dict),
   'Identify');

# This is a query that is fine to be send to nodes
is($koral_query->to_string(1),
   "gFields(#3:(#17|#4)&[1])",
   'Stringification');

ok(my $query = $koral_query->optimize($index->segment), 'optimize query');

is($query->to_string, 'gFields(#3:and(or(#17,#4),[1]))', 'Stringification');

ok($query->next, 'Go to next');
ok($query->finalize, 'Go to next');

# TODO:
#   This API is only temporarily implemented
is($query->collection->to_string, 'gFields:[#3:[18=1,1;4=3,3]',
   'Stringification');

is($query->collection->inflate($index->dict)->to_string,
   'gFields:[author:[Michael:1,1;Peter:3,3]',
   'Stringification inflated');




# Corpus object
$koral->corpus(
  $cb->bool_or(
    $cb->string('age')->eq('3'),
    $cb->string('age')->eq('7')
  )
);

# Compile object
$koral->compilation(
  $mb->group_by(
    $mb->g_fields('author', 'genre')
  )
);

$koral->query(
  $qb->bool_or($qb->term('aa'), $qb->term('bb'))
);

is($koral->to_string,
   "compilation=[group=[fields:['author','genre']]],corpus=[age=3|age=7],query=[aa|bb]",
   'Stringification');

ok($query = $koral->to_query->identify($index->dict)->optimize($index->segment), 'Optimize');

is($query->to_string,
   'gFields(#3,#5:filter(or(#10,#12),or(#17,#2)))',
   'Stringification');

ok(my $coll = $query->finalize->collection->inflate($index->dict), 'Search');

is($coll->to_string, 'gFields:[author,genre:[Michael|newsletter:1,2;Peter|novel:2,4]',
   'Stringification');

# TODO: Group on multiple fields!


done_testing;
__END__
