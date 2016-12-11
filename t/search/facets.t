use Test::More;
use Test::Krawfish;
use strict;
use warnings;

use_ok('Krawfish::Index');
use_ok('Krawfish::Koral::Query::Builder');
use_ok('Krawfish::Collect::Facets');

my $index = Krawfish::Index->new;

ok(defined $index->add('t/data/doc1.jsonld'), 'Add new document');
ok(defined $index->add('t/data/doc2.jsonld'), 'Add new document');
ok(defined $index->add('t/data/doc3-segments.jsonld'), 'Add new document');

my $kq = Krawfish::Koral::Query::Builder->new;
my $query = $kq->token('Der');

# Get facets object
ok(my $facets = Krawfish::Collect::Facets->new(
  $query->prepare_for($index),
  $index,
  [qw/license corpus/]
), 'Create count object');

ok($facets->next, 'Next');
ok($facets->next, 'Next');
ok(!$facets->next, 'No more nexts');

my $hash = $facets->facets('license');
is($hash->{free}->[0], 1, 'Document frequency');
is($hash->{free}->[1], 1, 'frequency');
is($hash->{closed}->[0], 1, 'Document frequency');
is($hash->{closed}->[1], 1, 'frequency');

$hash = $facets->facets('corpus');
is($hash->{'corpus-2'}->[0], 2, 'Document frequency');
is($hash->{'corpus-2'}->[1], 2, 'frequency');

is($facets->to_string, "collectFacets(['license','corpus']:'Der')", 'Stringification');

done_testing;
__END__
