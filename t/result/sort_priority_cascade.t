use Test::More;
use Test::Krawfish;
use strict;
use warnings;

use_ok('Krawfish::Index');
use_ok('Krawfish::Koral::Query::Builder');
use_ok('Krawfish::Result::Sort::PriorityCascade');
use_ok('Krawfish::Result::Segment::Fields');

my $index = Krawfish::Index->new;

ok_index($index, {
  docID => 7,
  author => 'Arthur'
} => [qw/aa bb/], 'Add complex document');
ok_index($index, {
  docID => 3,
  author => 'Arthur'
} => [qw/aa bb cc/], 'Add complex document');
ok_index($index, {
  docID => 1,
  author => 'Bob'
} => [qw/aa bb cc/], 'Add complex document');

my $kq = Krawfish::Koral::Query::Builder->new;

my $query = $kq->term_or('aa', 'bb');

# Set maximum rank reference to the last doc id of the index
my $max_rank = $index->max_rank;

# Get sort object
ok(my $sort = Krawfish::Result::Sort::PriorityCascade->new(
  query => $query->normalize->finalize->optimize($index),
  index => $index,
  fields => [
    ['author'],  # Order by author with highest priority
    ['docID']    # Then by doc id
  ],
  unique => 'docID',
  top_k => 3,
  max_rank_ref => \$max_rank
), 'Create sort object');


ok(my $sort_fields = Krawfish::Result::Segment::Fields->new(
  $index,
  $sort,
  ['author', 'docID']
), 'Create fields object');


# This will be sorted by the doc id,
# so the doc-id=1 document will show up first
ok($sort_fields->next, 'First next');
is($sort_fields->current_match->to_string,
   q![1:0-1|author='Arthur';docID='3']!, 'Match');
is($sort_fields->current->doc_id, 1, 'DocID');


ok($sort_fields->next, 'Next');
is($sort_fields->current_match->to_string,
   q![1:1-2|author='Arthur';docID='3']!, 'Match');
is($sort_fields->current->doc_id, 1, 'DocID');


ok($sort_fields->next, 'Next');
is($sort_fields->current_match->to_string,
   q![0:0-1|author='Arthur';docID='7']!, 'Match');
is($sort_fields->current->doc_id, 0, 'DocID');


ok(!$sort_fields->next, 'Next');

TODO: {
  local $TODO = 'Test with unique field';
};

done_testing;
__END__

