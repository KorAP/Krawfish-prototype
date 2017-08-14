use Test::More;
use Test::Krawfish;
use strict;
use warnings;

use_ok('Krawfish::Index');
use_ok('Krawfish::Koral');

# Create some documents
my $index = Krawfish::Index->new;
ok_index_2($index, {
  id => 2,
  author => 'Peter',
  genre => 'novel',
  age => 4
} => [qw/aa bb/], 'Add complex document');
ok_index_2($index, {
  id => 3,
  author => 'Peter',
  genre => 'novel',
  age => 3
} => [qw/aa bb/], 'Add complex document');
ok_index_2($index, {
  id => 5,
  author => 'Peter',
  genre => 'newsletter',
  title => 'Your way to success!',
  age => 4
} => [qw/aa bb/], 'Add complex document');
ok_index_2($index, {
  id => 6,
  author => 'Michael',
  genre => 'newsletter',
  age => 7
} => [qw/aa bb/], 'Add complex document');

# ok(defined $index->add('t/data/doc1.jsonld'), 'Add new document');
# ok(defined $index->add('t/data/doc2.jsonld'), 'Add new document');
# ok(defined $index->add('t/data/doc3-segments.jsonld'), 'Add new document');

my $koral = Krawfish::Koral->new;
my $qb = $koral->query_builder;
my $mb = $koral->meta_builder;

$koral->query($qb->token('aa'));

$koral->meta(
  $mb->aggregate(
    $mb->a_facets('genre'),
    $mb->a_facets('age')
  )
);

is($koral->to_string,
   "meta=[aggr=[facets:['genre'],facets:['age']]],query=[[aa]]",
   'Stringification');

ok(my $koral_query = $koral->to_query, 'Normalization');

# This is a query that is fine to be send to nodes
is($koral_query->to_string,
   "aggr(facets:['genre','age']:filter(aa,[1]))",
   'Stringification');

# This is a query that is fine to be send to segments:
ok($koral_query = $koral_query->identify($index->dict), 'Identify');


# This is a query that is fine to be send to nodes
is($koral_query->to_string,
   "aggr(facets:[#5,#1]:filter(#10,[1]))",
   'Stringification');

diag 'check facets!';

done_testing;
__END__



ok(my $koral_nodes = $koral->to_nodes, 'Normalization');

is($koral_nodes->to_string, "fields('id':sort(field='id'<:aggr(facets:['license','corpus']:filter(Der,[1]))))", 'Stringification');

use_ok('Krawfish::Result::Segment::Aggregate');
use_ok('Krawfish::Result::Segment::Aggregate::Facets');


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
