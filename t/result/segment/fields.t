use Test::More;
use Test::Krawfish;
use strict;
use warnings;

use_ok('Krawfish::Index');
use_ok('Krawfish::Koral::Query::Builder');
use_ok('Krawfish::Result::Segment::Fields');

my $index = Krawfish::Index->new;
ok_index($index, {
  docID => 'doc-1',
  license => 'free',
  corpus => 'corpus-2'
} => [qw/aa bb/], 'Add new document');
ok_index($index, {
  docID => 'doc-2',
  license => 'closed',
  corpus => 'corpus-3'
} => [qw/aa bb/], 'Add new document');
ok_index($index, {
  docID => 'doc-3',
  license => 'free',
  corpus => 'corpus-1'
} => [qw/bb cc/], 'Add new document');

my $kq = Krawfish::Koral::Query::Builder->new;
my $query = $kq->token('aa');

# Get fields object
ok(my $fields = Krawfish::Result::Segment::Fields->new(
  $index,
  $query->prepare_for($index),
  [qw/license corpus/]
), 'Create count object');

ok($fields->next, 'Next');
is($fields->current->to_string, '[0:0-1]', 'Current object');
is($fields->current_match, "[0:0-1|corpus='corpus-2';license='free']",
   'Current match');
ok($fields->next, 'Next');
is($fields->current_match, "[1:0-1|corpus='corpus-3';license='closed']",
   'Current match');
ok(!$fields->next, 'No more next');


# Fields for multiple spans
$query = $kq->term_or('aa', 'bb');


# Get fields object
ok($fields = Krawfish::Result::Segment::Fields->new(
  $index,
  $query->prepare_for($index),
  [qw/license corpus/]
), 'Create count object');

ok($fields->next, 'Next');
is($fields->current->to_string, '[0:0-1]', 'Current object');
is($fields->current_match, "[0:0-1|corpus='corpus-2';license='free']",
   'Current match');

ok($fields->next, 'Next');
is($fields->current->to_string, '[0:1-2]', 'Current object');
is($fields->current_match, "[0:1-2|corpus='corpus-2';license='free']",
   'Current match');

ok($fields->next, 'Next');
is($fields->current->to_string, '[1:0-1]', 'Current object');
is($fields->current_match, "[1:0-1|corpus='corpus-3';license='closed']",
   'Current match');

ok($fields->next, 'Next');
is($fields->current->to_string, '[1:1-2]', 'Current object');
is($fields->current_match, "[1:1-2|corpus='corpus-3';license='closed']",
   'Current match');

ok($fields->next, 'Next');
is($fields->current->to_string, '[2:0-1]', 'Current object');
is($fields->current_match, "[2:0-1|corpus='corpus-1';license='free']",
   'Current match');

ok(!$fields->next, 'Next');

done_testing;
__END__


