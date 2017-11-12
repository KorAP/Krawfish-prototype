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

is($query->to_string,
   'filter(unique({3:#11|(#8&#9)}[]#8{1,4}),(#13|#4)&(#16|#5))',
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
    $comp->a_fields(qw/author/),
    $comp->a_frequencies,
    $comp->a_length,
    $comp->a_values(qw/size/)
  ),
  $comp->enrich(
    $comp->e_fields(qw/size/),
    $comp->e_corpus_classes(3,4) # TODO: Ignore corpus classes, in case they are not set!
  ),
  $comp->sort_by(
    $comp->s_field('genre')
  )
);

# Check stringification
is($koral->to_string,
   "compilation=[".
     "aggr=[fields:['author'],freq,length,values:['size']],".
     "enrich=[fields:['size'],".
     "corpusclasses:[3,4]],".
     "sort=[field='genre'<]".
     "],".
     "query=[[a]]",
   'Serialization');

ok($query = $koral->to_query->identify($index->dict)->optimize($index->segment), 'Query generation');
#ok($clone = $query->clone, 'Cloning');

#is($query->to_string,
#  '[0]',
#  'Stringification');

# Run query
#is($query->compile->inflate($index->dict)->to_string,
#  '',
#  'Stringification');


# Test cloning (and running)
diag 'Check compile queries';

done_testing;
__END__
