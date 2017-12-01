use Test::More;
use Test::Krawfish;
use strict;
use warnings;

use_ok('Krawfish::Koral');
use_ok('Krawfish::Index');
use_ok('Krawfish::Index::Segment');
use_ok('Krawfish::Compile::Node::Sort');

ok(my $index = Krawfish::Index->new(':temp1:'), 'Create new index object');

# Add secondary segment
$index->add_segment(Krawfish::Index::Segment->new(':temp:'));

ok($index->introduce_field('id', 'NUM'), 'Introduce field as sortable');
ok($index->introduce_field('author', 'DE'), 'Introduce field as sortable');
ok($index->introduce_field('genre', 'DE'), 'Introduce field as sortable');

# Fill node 1
ok_index_koral($index => 0, test_doc({
  id => 1,
  author => 'Peter',
  genre => 'newsletter',
} => [qw/aa bb aa cc/]), 'Add document to segment 0');
ok_index_koral($index => 0, test_doc({
  id => 3,
  author => 'Frank',
  genre => 'novel',
} => [qw/aa aa cc bb/]), 'Add document to segment 0');
ok_index_koral($index => 0, test_doc({
  id => 5,
  author => 'Joachim',
  genre => 'novel',
} => [qw/aa aa bb cc/]), 'Add document to segment 0');
ok_index_koral($index => 0, test_doc({
  id => 7,
  author => 'Martin',
  genre => 'newsletter',
} => [qw/cc aa bb cc/]), 'Add document to segment 0');


# Add documents to second index
# (normally the second index is not dynamic, so this is just temporary)
ok_index_koral($index => 1, test_doc({
  id => 2,
  author => 'Lukas',
  genre => 'newsletter',
} => [qw/aa bb cc cc/]), 'Add document to segment 1');
ok_index_koral($index => 1, test_doc({
  id => 4,
  author => 'Abraham',
  genre => 'novel',
} => [qw/aa bb bb cc/]), 'Add document to segment 1');
ok_index_koral($index => 1, test_doc({
  id => 6,
  author => 'Xaver',
  genre => 'newsletter',
} => [qw/aa cc cc aa/]), 'Add document to segment 1');
ok_index_koral($index => 1, test_doc({
  id => 8,
  author => 'Henning',
  genre => 'novel',
} => [qw/aa bb aa cc/]), 'Add document to segment 1');


# Normally commiting only works on the first segment,
# so this is temporary
ok($index->segment(0)->commit, 'Commit to all segments');
ok($index->segment(1)->commit, 'Commit to all segments');

my $koral = Krawfish::Koral->new;
my $qb = $koral->query_builder;
my $mb = $koral->compilation_builder;

$koral->query(
  $qb->bool_or(
    $qb->seq(
      $qb->token('aa'),
      $qb->token('bb')
    ),
    $qb->seq(
      $qb->token('aa'),
      $qb->token('cc')
    )
  )
);

$koral->compilation(
  $mb->sort_by(
    $mb->s_field('author')
  )
);

ok(my $cluster_q = $koral->to_query, 'To cluster query');


is($cluster_q->to_string,
   "sort(field='id'<:sort(field='author'<:filter((aabb)|(aacc),[1])))",
   'Stringification');

my $node_q = $cluster_q->identify($index->dict);

is($node_q->to_string(1),
   "sort(field=#1<:sort(field=#2<:filter((#8#10)|(#8#12),[1])))",
   'Stringification');

my $node_query = Krawfish::Compile::Node::Sort->new(
  query => $node_q,
  top_k => 100,
  segments => $index->segments
);

is($node_query->to_string,
   'nSort(sort(field=#1<,l=1:sort(field=#2<:bundleDocs(or(constr(pos=2:#8,filter(#10,[1])),constr(pos=2:#8,filter(#12,[1]))))));sort(field=#1<,l=1:sort(field=#2<:bundleDocs(or(constr(pos=2:#8,filter(#10,[1])),constr(pos=2:#8,filter(#12,[1])))))))',
   'Stringification');


# 0:Peter:1, 1:Frank:3, 2:Joachim:5, 3:Martin:7,
# 4:Lukas:2, 5:Abraham:4, 6:Xaver:6, 7:Henning:8
# ->
# 5:Abraham:4, 1:Frank:3, 7:Henning:8, 2:Joachim:5,
# 4:Lukas:2, 3:Martin:7, 0:Peter:1, 6:Xaver:6
# It is relevant to return the id!

ok($node_query->next, 'Move to next node');
is($node_query->current_match->to_string, '[1:0-2::GQw..A==,4]', 'match');
is($node_query->current_match->uuid, 4, 'match');
ok($node_query->next, 'Move to next node');
is($node_query->current_match->to_string, '[1:1-3::Gak..wAA,3]', 'match');
ok($node_query->next, 'Move to next node');
is($node_query->current_match->to_string, '[3:0-2::Gdw..A==,8]', 'match');
ok($node_query->next, 'Move to next node');
is($node_query->current_match->to_string, '[3:2-4::Gdw..A==,8]', 'match');
ok($node_query->next, 'Move to next node');
is($node_query->current_match->to_string, '[2:1-3::GhA..A==,5]', 'match');
ok($node_query->next, 'Move to next node');
is($node_query->current_match->to_string, '[0:0-2::Gjs..wAA,2]', 'match');
ok($node_query->next, 'Move to next node');
is($node_query->current_match->to_string, '[3:1-3::Gm4..AA=,7]', 'match');
ok($node_query->next, 'Move to next node');
is($node_query->current_match->to_string, '[0:0-2::Gs4..wAA,1]', 'match');
ok($node_query->next, 'Move to next node');
is($node_query->current_match->to_string, '[0:2-4::Gs4..wAA,1]', 'match');
ok($node_query->next, 'Move to next node');
is($node_query->current_match->to_string, '[2:0-2::G8E..wAA,6]', 'match');
ok(!$node_query->next, 'Move to next node');


done_testing;
__END__

