use Test::More;
use Test::Krawfish;
use strict;
use warnings;

use_ok('Krawfish::Index');
use_ok('Krawfish::Koral::Query::Builder');
use_ok('Krawfish::Result::Count');

my $index = Krawfish::Index->new;

ok_index($index, {
  docID => 7
} => [qw/aa bb/], 'Add complex document');
ok_index($index, {
  docID => 3,
} => [qw/aa cc cc/], 'Add complex document');
ok_index($index, {
  docID => 1,
} => [qw/aa bb/], 'Add complex document');


my $kq = Krawfish::Koral::Query::Builder->new;

my $query = $kq->token('bb');

# Get count object
ok(my $count = Krawfish::Result::Count->new(
  $query->prepare_for($index)
), 'Create count object');

ok($count->next, 'Next');
ok($count->next, 'Next');
ok(!$count->next, 'No more nexts');

my ($doc_freq, $freq) = $count->frequencies;

is($doc_freq, 2, 'Document frequency');
is($freq, 2, 'Occurrence frequency');

is($count->to_string, "collectCounts('bb')", 'Get counts');


$query = $kq->token('cc');

# Get count object
ok($count = Krawfish::Result::Count->new(
  $query->prepare_for($index)
), 'Create count object');

ok($count->finish, 'Finish');
($doc_freq, $freq) = $count->frequencies;

is($doc_freq, 1, 'Document frequency');
is($freq, 2, 'Occurrence frequency');
is($count->to_string, "collectCounts('cc')", 'Get counts');


done_testing;
__END__
