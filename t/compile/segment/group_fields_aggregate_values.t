use Test::More;
use Test::Krawfish;
use Data::Dumper;
use strict;
use warnings;

use_ok('Krawfish::Index');
use_ok('Krawfish::Koral');

my $koral = Krawfish::Koral->new;
my $mb = $koral->compilation_builder;

# Compile object
$koral->compilation(
  $mb->group_by(
    $mb->g_fields('author')
  ),
  $mb->aggregate(
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
