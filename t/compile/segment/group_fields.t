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
  category => 'new',
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
  category => 'new',
  age => 4
} => [qw/aa bb/], 'Add complex document');
ok_index($index, {
  id => 6,
  author => 'Michael',
  genre => 'newsletter',
  category => 'new',
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
   "gFields(#3:(#19|#4)&[1])",
   'Stringification');

ok(my $query = $koral_query->optimize($index->segment), 'optimize query');

is($query->to_string, 'gFields(#3:and(or(#19,#4),[1]))', 'Stringification');

ok(my $result = $query->compile->inflate($index->dict), 'Compile');

is($result->to_string, "[group=[fields=['author'];total:['Michael':[1,1],'Peter':[3,3]]]]",
   'Group result');


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
   'gFields(#3,#7:filter(or(#12,#14),or(#19,#2)))',
   'Stringification');

ok($result = $query->compile->inflate($index->dict), 'Search');

is($result->to_string,
   "[group=[fields=['author','genre'];total:['Michael_newsletter':[1,2],'Peter_novel':[2,4]]]]",
   'Stringification');



# New query
$koral = Krawfish::Koral->new;

# Corpus object
$koral->corpus(
  $cb->bool_or(
    $cb->class($cb->string('genre')->eq('novel'), 1),
    $cb->class($cb->string('genre')->eq('newsletter'), 2),
  )
);

# Compile object
$koral->compilation(
  $mb->group_by(
    $mb->g_fields('author', 'age')
  )
);

$koral->query(
  $qb->bool_or($qb->term('aa'), $qb->term('bb'))
);

ok($query = $koral->to_query, 'To query');

is($query->to_string,
   "gFields('author','age':filter(aa|bb,{1:genre=novel}|{2:genre=newsletter}))",
   'Stringification');

ok($result = $query->identify($index->dict)->optimize($index->segment)->compile->inflate($index->dict),
   'Compile');

is($result->to_string,
   "[group=[fields=['age','author'];" .
     "total:['3_Peter':[2,4],'4_Peter':[1,2],'7_Michael':[1,2]],".
     "inCorpus-1:['3_Peter':[2,4]],".
     "inCorpus-2:['4_Peter':[1,2],'7_Michael':[1,2]]]]",
   'Stringification');

is($result->to_koral_query->{group}->{'@type'},
  'koral:groupBy',
  'KQ type');

is($result->to_koral_query->{group}->{'groupBy'},
  'groupBy:fields',
  'KQ type');

is_deeply($result->to_koral_query->{group}->{'fields'},
  [qw/age author/],
  'KQ type');

is_deeply($result->to_koral_query->{group}->{total}->[1],
          {
            '@type' => 'koral:row',
            docs => 1,
            matches => 2,
            cols => [4, 'Peter']
          },
          'KQ type');



# New query - with additional aggregation
$koral = Krawfish::Koral->new;

# Corpus object
$koral->corpus(
  $cb->bool_or(
    $cb->class($cb->string('genre')->eq('novel'), 1),
    $cb->class($cb->string('genre')->eq('newsletter'), 2),
  )
);

# Compile object
$koral->compilation(
  $mb->group_by(
    $mb->g_fields('author')
  ),
  $mb->aggregate(
    $mb->a_frequencies
  )
);

$koral->query(
  $qb->bool_or($qb->term('aa'), $qb->term('bb'))
);

ok($query = $koral->to_query, 'To query');

is($query->to_string,
   "gFields('author':aggr(freq:filter(aa|bb,{1:genre=novel}|{2:genre=newsletter})))",
   'Stringification');

ok($query = $query->identify($index->dict)->optimize($index->segment), 'Optimize');
is($query->to_string,
   'gFields(#3:aggr([freq]:filter(or(#12,#14),or(class(1:#8),class(2:#17)))))',
   'Stringification');

ok($result = $query->compile->inflate($index->dict), 'Compile');

is($result->to_string,
   "[aggr=[".
     "freq=".
     "total:[4,8];".
     "inCorpus-1:[2,4];".
     "inCorpus-2:[2,4]]]".
     "[group=[fields=['author'];".
     "total:['Michael':[1,2],'Peter':[3,6]],".
     "inCorpus-1:['Peter':[2,4]],".
     "inCorpus-2:['Michael':[1,2],'Peter':[1,2]]]]",
   'Stringification');



# New query - with additional aggregation
$koral = Krawfish::Koral->new;

# Compile object
$koral->compilation(
  $mb->group_by(
    $mb->g_fields('unknown','category', 'genre')
  )
);

$koral->query(
  $qb->bool_or($qb->term('aa'), $qb->term('bb'))
);

ok($query = $koral->to_query, 'To query');

is($query->to_string,
   "gFields('unknown','category','genre':filter(aa|bb,[1]))",
   'Stringification');

diag 'Respect unknown field';
# as it may only be unknown to this node!

ok($query = $query->identify($index->dict)->optimize($index->segment), 'Optimize');
is($query->to_string,
   'gFields(#5,#7:filter(or(#12,#14),[1]))',
   'Stringification');

ok($result = $query->compile->inflate($index->dict), 'Compile');

is($result->to_string,
   "[group=".
     "[fields=['category','genre'];".
     "total:[".
     "'_novel':[1,2],".
     "'new_newsletter':[2,4],".
     "'new_novel':[1,2]]".
     "]".
     "]",
   'Result stringification');

done_testing;
__END__
