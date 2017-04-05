use Test::More;
use Test::Krawfish;
use strict;
use warnings;

use_ok('Krawfish::Index');
use_ok('Krawfish::Koral::Query::Builder');
use_ok('Krawfish::Result::Aggregate');
use_ok('Krawfish::Result::Aggregate::Values');

my $index = Krawfish::Index->new;

ok_index($index, {
  docID => 7,
  size => 2,
} => [qw/aa bb/], 'Add complex document');
ok_index($index, {
  docID => 3,
  size => 3
} => [qw/aa cc cc/], 'Add complex document');
ok_index($index, {
  docID => 1,
  size => 2
} => [qw/aa bb/], 'Add complex document');


my $kq = Krawfish::Koral::Query::Builder->new;

my $query = $kq->token('bb');

my $field_count = Krawfish::Result::Aggregate::Values->new($index, 'size');

# Get count object
ok(my $aggr = Krawfish::Result::Aggregate->new(
  $query->prepare_for($index),
  [$field_count]
), 'Create field count object');

diag 'Field values are not yet defined';

done_testing;
__END__

ok($aggr->next, 'Next');
ok($aggr->next, 'Next');
ok(!$aggr->next, 'No more nexts');



is($count->doc_freq, 2, 'Document frequency');
is($count->freq, 2, 'Occurrence frequency');


is($aggr->to_string, "aggregate([count]:'bb')", 'Get counts');
$query = $kq->token('cc');

$count = Krawfish::Result::Aggregate::Count->new;

# Get count object
ok($aggr = Krawfish::Result::Aggregate->new(
  $query->prepare_for($index),
  [$count]
), 'Create count object');

ok($aggr->finish, 'Finish');
is($aggr->to_string, "aggregate([count]:'cc')", 'Get counts');
is($count->doc_freq, 1, 'Document frequency');
is($count->freq, 2, 'Occurrence frequency');

done_testing;
__END__
my $index = Krawfish::Index->new;

ok(defined $index->add('t/data/doc1.jsonld'), 'Add new document');
ok(defined $index->add('t/data/doc2.jsonld'), 'Add new document');
ok(defined $index->add('t/data/doc3-segments.jsonld'), 'Add new document');

my $kq = Krawfish::Koral::Query::Builder->new;
my $query = $kq->token('Der');

my $facet_license = Krawfish::Result::Aggregate::Facets->new(
  $index,
  'license'
);

my $facet_corpus = Krawfish::Result::Aggregate::Facets->new(
  $index,
  'corpus'
);

# Get facets object
ok(my $aggr = Krawfish::Result::Aggregate->new(
  $query->prepare_for($index),
  [$facet_license, $facet_corpus]
), 'Create count object');

is(
  $aggr->to_string,
  "aggregate([facet:license,facet:corpus]:'Der')",
  'Stringification'
);

ok($aggr->next, 'Next');
ok($aggr->next, 'Next');
ok(!$aggr->next, 'No more nexts');

my $hash = $facet_license->facets;
is($hash->{free}->[0], 1, 'Document frequency');
is($hash->{free}->[1], 1, 'frequency');
is($hash->{closed}->[0], 1, 'Document frequency');
is($hash->{closed}->[1], 1, 'frequency');

$hash = $facet_corpus->facets;
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
