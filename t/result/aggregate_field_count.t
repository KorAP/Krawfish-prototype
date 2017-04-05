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
  size => 2, # TODO: May need to be marked as numerical
} => [qw/aa bb/], 'Add complex document');
ok_index($index, {
  docID => 3,
  size => 3,
} => [qw/aa cc cc/], 'Add complex document');
ok_index($index, {
  docID => 1,
  size => 2,
} => [qw/aa bb/], 'Add complex document');


my $kq = Krawfish::Koral::Query::Builder->new;

my $query = $kq->token('bb');

my $field_count = Krawfish::Result::Aggregate::Values->new($index, ['size', 'docID']);

# Get count object
ok(my $aggr = Krawfish::Result::Aggregate->new(
  $query->prepare_for($index),
  [$field_count]
), 'Create field count object');

ok($aggr->finalize, 'Final');

is_deeply($aggr->result, {
  aggregate => {
    size => {
      min => 2,
      max => 2,
      sum => 4,
      avg => 2,
      freq => 2
    },
    docID => {
      min => 1,
      max => 7,
      sum => 8,
      avg => 4,
      freq => 2
    }
  }
}, 'Field values');


done_testing;
__END__
