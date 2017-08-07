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
ok_index($index, {
  id => 1,
  genre => 'novel',
} => '[a|b]<1:x>[a|b|c]</1>[a][b|c]', 'Add complex document');
ok_index($index, {
  id => 2,
  genre => 'news',
} => '[a|b][a|b|c][a][b|c]', 'Add complex document');
ok_index($index, {
  id => 3,
  genre => 'novel',
} => '<1:x>[a|b][a|b|c][a]</1>[b|c]', 'Add complex document');

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
      $qb->any,
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
   'filter(unique({3:(#5&#6)|#8}[]#5{1,4}),(#11|#3)&(#1|#9))',
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


done_testing;
__END__
