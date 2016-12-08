use Test::More;
use Test::Krawfish;
use strict;
use warnings;

use_ok('Krawfish::Index');
use_ok('Krawfish::Koral::Query::Builder');
use_ok('Krawfish::Search::Count');

my $index = Krawfish::Index->new;

ok(defined $index->add('t/data/doc1.jsonld'), 'Add new document');
ok(defined $index->add('t/data/doc2.jsonld'), 'Add new document');
ok(defined $index->add('t/data/doc3-segments.jsonld'), 'Add new document');

my $kq = Krawfish::Koral::Query::Builder->new;
my $query = $kq->token('Der');

# Get count object
ok(my $count = Krawfish::Search::Count->new(
  $query->prepare_for($index)
), 'Create count object');

ok($count->next, 'Next');
ok($count->next, 'Next');
ok(!$count->next, 'No more nexts');

my ($doc_freq, $freq) = $count->frequencies;

is($doc_freq, 2, 'Document frequency');
is($freq, 2, 'Occurrence frequency');


done_testing;
__END__
