use Test::More;
use Test::Krawfish;
use strict;
use warnings;

use_ok('Krawfish::Index');
use_ok('Krawfish::Koral::Query::Builder');
use_ok('Krawfish::Result::Segment::Aggregate');
use_ok('Krawfish::Result::Segment::Aggregate::Length');

my $index = Krawfish::Index->new;

ok_index($index, {
  docID => 7
} => '<1:s>[Der][hey]</1>', 'Add complex document');
ok_index($index, {
  docID => 3,
} => '<1:s>[Der]</1>[Baum]', 'Add complex document');
ok_index($index, {
  docID => 1,
} => '<1:s>[Der]</1><2:s>[alte][graue][Baum]</2>', 'Add complex document');


my $kq = Krawfish::Koral::Query::Builder->new;

my $query = $kq->span('s');

my $length = Krawfish::Result::Segment::Aggregate::Length->new;

# Get length object
ok(my $aggr = Krawfish::Result::Segment::Aggregate->new(
  $query->prepare_for($index),
  [$length]
), 'Create length object');

is($aggr->to_string, q!aggregate([length]:'<>s')!, 'Stringification');

ok($aggr->next, 'Next');
ok($aggr->next, 'Next');
ok($aggr->next, 'Next');
ok($aggr->next, 'Next');
ok(!$aggr->next, 'No more nexts');

is_deeply($aggr->result, {
  length => {
    avg => 1.75,
    min => 1,
    max => 3,
    sum => 7
  }
}, 'Get aggregation results');


done_testing;
__END__
