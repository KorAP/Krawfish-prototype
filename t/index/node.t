use Test::More;
use Test::Krawfish;
use strict;
use warnings;

use_ok('Krawfish::Koral');
use_ok('Krawfish::Index');
use_ok('Krawfish::Index::Segment');

ok(my $index = Krawfish::Index->new(':temp1:'), 'Create new index object');

# Add secondary segment
$index->add_segment(Krawfish::Index::Segment->new(':temp:'));

ok($index->introduce_field('id', 'NUM'), 'Introduce field as sortable');
ok($index->introduce_field('author', 'DE'), 'Introduce field as sortable');

ok_index_koral($index => 0, test_doc({
  id => 2,
  author => 'Peter',
  genre => 'novel',
  age => 4
} => [qw/aa bb aa cc/]), 'Add document to segment 1');


# Add documents to second index
# (normally the second index is not dynamic, so this is just temporary)
ok_index_koral($index => 1, test_doc({
  id => 5,
  author => 'Michael',
  genre => 'newsletter',
  title => 'Your new way to success!',
  age => 7
} => [qw/aa bb/]), 'Add document to segment 1');


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
  $mb->enrich(
    $mb->e_fields(qw/author/)
  )
);

ok(my $cluster_q = $koral->to_query, '');

is($cluster_q->to_string, "fields('author':filter((aabb)|(aacc),[1]))", 'Stringification');

my $node_q = $cluster_q->identify($index->dict);

is($node_q->to_string(1), "fields(#2:filter((#10#12)|(#10#14),[1]))", 'Stringification');

ok(my $seg_q_1 = $node_q->optimize($index->segment(0)), 'Run on index 1');
ok(my $seg_q_2 = $node_q->optimize($index->segment(1)), 'Run on index 2');

is($seg_q_1->to_string(1),
   'eFields(2:or(constr(pos=2:#10,filter(#12,[1])),constr(pos=2:#10,filter(#14,[1]))))',
   'Stringification 1');

# There is no 'cc' in segment 1
is($seg_q_2->to_string(1),
   'eFields(2:constr(pos=2:#10,filter(#12,[1])))',
   'Stringification 2');

is($seg_q_1->compile->inflate($index->dict)->to_string,
   "[matches=[0:0-2|fields:'author'='Peter'][0:2-4|fields:'author'='Peter']]",
   'Stringification');

is($seg_q_2->compile->inflate($index->dict)->to_string,
   "[matches=[0:0-2|fields:'author'='Michael']]",
   'Stringification');


done_testing;
__END__






done_testing;
__END__
