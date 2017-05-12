use Test::More;
use Test::Krawfish;
use strict;
use warnings;

use_ok('Krawfish::Index');
use_ok('Krawfish::Koral::Query::Builder');
use_ok('Krawfish::Result::Segment::Aggregate');
use_ok('Krawfish::Result::Segment::Aggregate::Count');

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

my $count = Krawfish::Result::Segment::Aggregate::Count->new;

# Get count object
ok(my $aggr = Krawfish::Result::Segment::Aggregate->new(
  $query->prepare_for($index),
  [$count]
), 'Create count object');

ok($aggr->next, 'Next');
ok($aggr->next, 'Next');
ok(!$aggr->next, 'No more nexts');


is($aggr->result->{totalResources}, 2, 'Document frequency');
is($aggr->result->{totalResults}, 2, 'Occurrence frequency');

is($aggr->to_string, "aggregate([count]:'bb')", 'Get counts');
$query = $kq->token('cc');

$count = Krawfish::Result::Segment::Aggregate::Count->new;

# Get count object
ok($aggr = Krawfish::Result::Segment::Aggregate->new(
  $query->prepare_for($index),
  [$count]
), 'Create count object');

# Search till the end
ok($aggr->finalize, 'Finish');

# Stringify
is($aggr->to_string, "aggregate([count]:'cc')", 'Get counts');

is($aggr->result->{totalResources}, 1, 'Document frequency');
is($aggr->result->{totalResults}, 2, 'Occurrence frequency');

done_testing;
__END__
