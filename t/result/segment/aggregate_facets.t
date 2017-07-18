use Test::More;
use Test::Krawfish;
use strict;
use warnings;

use_ok('Krawfish::Index');
use_ok('Krawfish::Koral::Query::Builder');
use_ok('Krawfish::Result::Segment::Aggregate');
use_ok('Krawfish::Result::Segment::Aggregate::Facets');

my $index = Krawfish::Index->new;

ok(defined $index->add('t/data/doc1.jsonld'), 'Add new document');
ok(defined $index->add('t/data/doc2.jsonld'), 'Add new document');
ok(defined $index->add('t/data/doc3-segments.jsonld'), 'Add new document');

my $kq = Krawfish::Koral::Query::Builder->new;
my $query = $kq->token('Der');

my $facet_license = Krawfish::Result::Segment::Aggregate::Facets->new(
  $index,
  'license'
);

my $facet_corpus = Krawfish::Result::Segment::Aggregate::Facets->new(
  $index,
  'corpus'
);

# Get facets object
ok(my $aggr = Krawfish::Result::Segment::Aggregate->new(
  $query->normalize->finalize->optimize($index),
  [$facet_license, $facet_corpus]
), 'Create facet object');

is(
  $aggr->to_string,
  "aggregate([facet:'license',facet:'corpus']:'Der')",
  'Stringification'
);

ok($aggr->next, 'Next');
ok($aggr->next, 'Next');
ok(!$aggr->next, 'No more nexts');

my $hash = $aggr->result->{facets}->{license};
is($hash->{free}->[0], 1, 'Document frequency');
is($hash->{free}->[1], 1, 'frequency');
is($hash->{closed}->[0], 1, 'Document frequency');
is($hash->{closed}->[1], 1, 'frequency');

$hash = $aggr->result->{facets}->{corpus};
is($hash->{'corpus-2'}->[0], 2, 'Document frequency');
is($hash->{'corpus-2'}->[1], 2, 'frequency');

is_deeply($aggr->result, {
  facets => {
    license => {
      free => [1,1],
      closed => [1,1]
    },
    corpus => {
      'corpus-2' => [2,2]
    }
  }
}, 'aggregated results');

done_testing;
__END__


done_testing;
__END__
