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
    $mb->a_values('size')
  )
);

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
