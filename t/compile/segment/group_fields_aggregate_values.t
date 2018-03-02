use Test::More;
use Test::Krawfish;
use Data::Dumper;
use strict;
use warnings;

use_ok('Krawfish::Koral::Result::Group::Aggregates');

my $aggrs = Krawfish::Koral::Result::Group::Aggregates->new;

# Get group
ok(my $aggr = $aggrs->aggregates(
  [
    [qw/a b c/],
    [qw/d e f/],
    [qw/g h i/]
  ]));

# First group
ok($aggr->[0], 'First group defined');

# Set first value at flags 4
$aggr->[0]->{4}->[0] = 2;

# Get group with same signature
is($aggrs->aggregates([[qw/a b c/]])->[0]->{4}->[0], 2);


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

my $koral = Krawfish::Koral->new;
my $mb = $koral->compilation_builder;

# Compile object
$koral->compilation(
  $mb->group_by(
    $mb->g_fields('author')
  ),

  # Group aggregates need a different name,
  # as match number etc. may
  # need to be aggregated globally in addition
  $mb->group_aggregate(
    $mb->a_values('age')
  )
);

is($koral->to_string,
   "compilation=[group=[fields:['author']],gaggr=[values:['age']]]",
   'String'
 );

ok(my $query = $koral->to_query, 'Normalize');

# TODO:
#   Simplify [1]&[1]!!!
is($query->to_string, "gaggr(values:['age']:gFields('author':[1]&[1]))", 'string');

ok($query = $query->identify($index->dict)->optimize($index->segment), 'Optimize');

is($query->to_string(1), 'gFields(#3;groupAggr([values:#1]):and([1],[1]))', 'Optimized query');

diag 'Implement Group::Aggregate!!';

# Example:
#   Group all documents in a VC based
#   on their corpusSigle and corpusTitle
#   and also list the sum() of their sentences.
#
#   Group on the surface form of class 1 and 2
#   and also list the avg() of both token lengths.
#   (weird)

done_testing;
