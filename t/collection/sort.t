use Test::More;
use Test::Krawfish;
use strict;
use warnings;

use_ok('Krawfish::Index');
use_ok('Krawfish::Koral::Query::Builder');
use_ok('Krawfish::Collection::Sort');

my $index = Krawfish::Index->new;

ok_index($index, {
  docID => 7
} => [qw/aa bb/], 'Add complex document');
ok_index($index, {
  docID => 3,
} => [qw/aa bb/], 'Add complex document');
ok_index($index, {
  docID => 1,
} => [qw/aa bb/], 'Add complex document');

my $kq = Krawfish::Koral::Query::Builder->new;
my $query = $kq->term_or('aa', 'bb');

# Get sort object
ok(my $sort = Krawfish::Collection::Sort->new(
  $query->prepare_for($index),
  $index,
  ['docID']
), 'Create sort object');

is($sort->freq, 6, 'List has frequency');
ok($sort->next, 'Next');
is($sort->current->doc_id, 2, 'Obj');
ok($sort->next, 'Next');
is($sort->current->doc_id, 2, 'Obj');

is($sort->to_string, "collectSorted(['docID']:or('aa','bb'))", 'Get counts');

done_testing;
__END__


ok($sort->next, 'Next');
is($sort->current->doc_id, 1, 'Obj');
ok($sort->next, 'Next');
is($sort->current->doc_id, 1, 'Obj');
ok($sort->next, 'Next');
is($sort->current->doc_id, 0, 'Obj');
ok($sort->next, 'Next');
is($sort->current->doc_id, 0, 'Obj');
ok(!$sort->next, 'No more nexts');

