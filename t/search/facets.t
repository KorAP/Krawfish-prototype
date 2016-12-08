use Test::More;
use Test::Krawfish;
use strict;
use warnings;

use_ok('Krawfish::Index');
use_ok('Krawfish::Koral::Query::Builder');
use_ok('Krawfish::Search::FieldFacets');

my $index = Krawfish::Index->new;

ok(defined $index->add('t/data/doc1.jsonld'), 'Add new document');
ok(defined $index->add('t/data/doc2.jsonld'), 'Add new document');
ok(defined $index->add('t/data/doc3-segments.jsonld'), 'Add new document');

my $kq = Krawfish::Koral::Query::Builder->new;
my $query = $kq->token('Der');

# Get count object
ok(my $count = Krawfish::Search::FieldFacets->new(
  $query->prepare_for($index),
  $index,
  [qw/license corpus/]
), 'Create count object');

ok($count->next, 'Next');
ok($count->next, 'Next');
ok(!$count->next, 'No more nexts');

# use Data::Dumper;
# diag Dumper $count->facets('license');

#is($doc_freq, 2, 'Document frequency');
#is($freq, 2, 'Occurrence frequency');

diag 'Test further';

done_testing;
__END__
