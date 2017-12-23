use Test::More;
use Test::Krawfish;
use strict;
use warnings;
use Data::Dumper;
use File::Basename 'dirname';
use File::Spec::Functions 'catfile';

use_ok('Krawfish::Index');
use_ok('Krawfish::Koral');

my $index = Krawfish::Index->new;

ok($index->introduce_field('id', 'NUM'),
   'Introduce field as sortable');
ok($index->introduce_field('size', 'NUM'),
   'Introduce field as sortable');
ok($index->introduce_field('genre', 'DE'),
   'Introduce field as sortable');

ok_index($index, {
  id => 1,
  integer_size => 4,
  genre => 'novel',
} => '[a|b]<1:x>[a|b|c]</1>[a][b|c]', 'Add complex document');
ok_index($index, {
  id => 2,
  integer_size => 5,
  genre => 'news',
} => '[a|b][a|b|c][a][b|c]', 'Add complex document');
ok_index($index, {
  id => 3,
  integer_size => 7,
  genre => 'novel',
} => '<1:x>[a|b][a|b|c][a]</1>[b|c]', 'Add complex document');

ok($index->commit, 'Commit data');


my $koral = Krawfish::Koral->new;
ok(my $qb = $koral->query_builder, 'Create Koral::Builder');
ok(my $cb = $koral->corpus_builder, 'Create Koral::Builder');


# Query building
$koral->query(
  $qb->unique(
    $qb->seq(
      $qb->class(
        $qb->token(
          $qb->bool_or(
            $qb->bool_and(
              $qb->term('a'),
              $qb->term('b')
            ),
            $qb->term('c')
          )
        ),
        3
      ),
      $qb->anywhere,
      $qb->repeat(
        $qb->term('a'),
        1,
        4
      )
    )
  )
);

# Corpus building
$koral->corpus(
  $cb->bool_and(
    $cb->bool_or(
      $cb->string('genre')->eq('novel'),
      $cb->string('genre')->eq('news')
    ),
    $cb->bool_or(
      $cb->string('id')->eq('1'),
      $cb->string('id')->eq('3')
    )
  )
);

is($koral->to_string,
   'corpus=[(genre=news|genre=novel)&(id=1|id=3)],query=[unique({3:[(a&b)|c]}[]a{1,4})]',
   'stringification');

ok(my $query = $koral->to_query, 'Query generation');

is($query->to_string,
   'filter(unique({3:(a&b)|c}[]a{1,4}),(genre=news|genre=novel)&(id=1|id=3))',
   'stringification');


ok($query = $query->identify($index->dict), 'Identify');

is($query->to_string(1),
   'filter(unique({3:(#8&#9)|#11}[]#8{1,4}),(#13|#4)&(#16|#5))',
   'stringification');

ok($query = $query->optimize($index->segment), 'Materialize');

ok(my $clone = $query->clone, 'Cloning');

ok($query->next, 'Next match found');
is($query->current->to_string, '[0:0-3$0,3,0,1]', 'Current match');
ok($query->next, 'Next match found');
is($query->current->to_string, '[2:0-3$0,3,0,1]', 'Current match');
ok(!$query->next, 'Next match found');

ok($clone->next, 'Next match found');
is($clone->current->to_string, '[0:0-3$0,3,0,1]', 'Current match');
ok($clone->next, 'Next match found');
is($clone->current->to_string, '[2:0-3$0,3,0,1]', 'Current match');
ok(!$clone->next, 'Next match found');


$koral = Krawfish::Koral->new;
ok(my $comp = $koral->compilation_builder, 'Create Koral::Builder');
$koral->query($qb->token('a'));
$koral->compilation(
  $comp->aggregate(
    $comp->a_fields(qw/genre/),
    $comp->a_frequencies,
    $comp->a_length,
    $comp->a_values(qw/size/)
  ),
  $comp->enrich(
    $comp->e_fields(qw/size/),
    $comp->e_corpus_classes(3,4) # TODO: Ignore corpus classes, in case they are not set!
  ),

  # TODO:
  #   Sorting and enrichment can't be combined!
  # $comp->sort_by(
  #  $comp->s_field('genre')
  # )
);

# Check stringification
is($koral->to_string,
   "compilation=[".
     "aggr=[".
       "fields:['genre'],".
       "freq,".
       "length,".
       "values:['size']".
     "],".
     "enrich=[".
       "fields:['size'],".
       "corpusclasses:[3,4]".
     "]".
   "],".
   "query=[[a]]",
   'Serialization');

ok($query = $koral->to_query, 'Wrap queries');

is($query->to_string,
  "corpusclasses(3,4:fields('size':aggr(length,freq,fields:['genre'],values:['size']:filter(a,[1]))))",
  'Stringification');


ok($query = $query->identify($index->dict)->optimize($index->segment), 'Query generation');

is($query->to_string,
  'eCorpusClasses(6144:eFields(#2:aggr([length,freq,fields:#3,values:#2]:filter(#8,[1]))))',
  'Stringification');

ok($clone = $query->clone, 'Cloning');

is($clone->to_string, $query->to_string, 'Clone is identical in regards to stringification');


# Run query
is($query->compile->inflate($index->dict)->to_string,
   '[aggr='.
     '[length=total:[avg:1,freq:9,min:1,max:1,sum:9]]'.
     '[freq=total:[3,9]]'.
     '[fields=total:[genre=news:[1,3],novel:[2,6]]]'.
     '[values=total:[size:[sum:16,freq:3,min:4,max:7,avg:5.33333333333333]]]'.
   ']'.
   '[matches='.
     "[0:0-1|fields:'size'=4]".
     "[0:1-2|fields:'size'=4]".
     "[0:2-3|fields:'size'=4]".
     "[1:0-1|fields:'size'=5]".
     "[1:1-2|fields:'size'=5]".
     "[1:2-3|fields:'size'=5]".
     "[2:0-1|fields:'size'=7]".
     "[2:1-2|fields:'size'=7]".
     "[2:2-3|fields:'size'=7]".
   ']',
  'Stringification');


# Run clone
is($clone->compile->inflate($index->dict)->to_string,
   '[aggr='.
     '[length=total:[avg:1,freq:9,min:1,max:1,sum:9]]'.
     '[freq=total:[3,9]]'.
     '[fields=total:[genre=news:[1,3],novel:[2,6]]]'.
     '[values=total:[size:[sum:16,freq:3,min:4,max:7,avg:5.33333333333333]]]'.
   ']'.
   '[matches='.
     "[0:0-1|fields:'size'=4]".
     "[0:1-2|fields:'size'=4]".
     "[0:2-3|fields:'size'=4]".
     "[1:0-1|fields:'size'=5]".
     "[1:1-2|fields:'size'=5]".
     "[1:2-3|fields:'size'=5]".
     "[2:0-1|fields:'size'=7]".
     "[2:1-2|fields:'size'=7]".
     "[2:2-3|fields:'size'=7]".
   ']',
  'Stringification');


diag 'Check that sort never mixes with enrich!';

done_testing;
__END__
