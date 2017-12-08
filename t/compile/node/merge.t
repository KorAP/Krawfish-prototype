use Test::More;
use Test::Krawfish;
use strict;
use warnings;

use_ok('Krawfish::Koral');
use_ok('Krawfish::Index');
use_ok('Krawfish::Index::Segment');
use_ok('Krawfish::Compile::Node');

ok(my $index = Krawfish::Index->new(':temp1:'), 'Create new index object');

# Add secondary segment
$index->add_segment(Krawfish::Index::Segment->new(':temp:'));

ok($index->introduce_field('id', 'NUM'), 'Introduce field as sortable');
ok($index->introduce_field('author', 'DE'), 'Introduce field as sortable');
ok($index->introduce_field('genre', 'DE'), 'Introduce field as sortable');

# Fill node 1
ok_index_koral($index => 0, test_doc({
  integer_id => 1,
  author => 'Peter',
  genre => 'newsletter',
  integer_size => 4
} => [qw/aa bb aa cc/]), 'Add document to segment 0');
ok_index_koral($index => 0, test_doc({
  integer_id => 3,
  author => 'Frank',
  genre => 'novel',
  integer_size => 4
} => [qw/aa aa cc bb/]), 'Add document to segment 0');
ok_index_koral($index => 0, test_doc({
  integer_id => 5,
  author => 'Joachim',
  genre => 'novel',
  integer_size => 4
} => [qw/aa aa bb cc/]), 'Add document to segment 0');
ok_index_koral($index => 0, test_doc({
  integer_id => 7,
  author => 'Martin',
  genre => 'newsletter',
  integer_size => 4
} => [qw/cc aa bb cc/]), 'Add document to segment 0');


# Add documents to second index
# (normally the second index is not dynamic, so this is just temporary)
ok_index_koral($index => 1, test_doc({
  integer_id => 2,
  author => 'Lukas',
  genre => 'newsletter',
  integer_size => 8
} => [qw/aa bb cc cc aa bb aa bb/]), 'Add document to segment 1');
ok_index_koral($index => 1, test_doc({
  integer_id => 4,
  author => 'Abraham',
  genre => 'novel',
  integer_size => 4
} => [qw/aa bb bb cc/]), 'Add document to segment 1');
ok_index_koral($index => 1, test_doc({
  integer_id => 6,
  author => 'Xaver',
  genre => 'newsletter',
  integer_size => 5
} => [qw/aa cc cc aa xx/]), 'Add document to segment 1');
ok_index_koral($index => 1, test_doc({
  integer_id => 8,
  author => 'Henning',
  genre => 'novel',
  integer_size => 6
} => [qw/aa bb aa cc xx yy/]), 'Add document to segment 1');


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
  $mb->aggregate(
    $mb->a_fields(qw/genre size/),
    $mb->a_frequencies,
    $mb->a_values('size'),
    $mb->a_length
  ),
  $mb->sort_by(
    $mb->s_field('author'),
  )
);

# Here it is possible to pass a potential
# replicant
ok(my $cluster_q = $koral->to_segments, 'To cluster query');

is($cluster_q->to_string,
   "node(k=100:sort(field='id'<:sort(field='author'<:aggr(length,freq,fields:['genre','size'],values:['size']:filter((aabb)|(aacc),[1])))))",
   'Stringification');

my $node_q = $cluster_q->identify($index->dict);

is($node_q->to_string(1),
   "node(k=100:sort(field=#1<:sort(field=#2<:aggr(length,freq,fields:[#3,#7],values:[#7]:filter((#10#12)|(#10#14),[1])))))",
   'Stringification');

ok(my $node_query = $node_q->optimize($index->segments), 'Optimize');

is($node_query->aggregate->inflate($index->dict)->to_string,
   '[aggr='.
     '[length=total:[avg:2,freq:12,min:2,max:2,sum:24]]' .
     '[freq=total:[8,12]]'.
     '[fields=total:'.
       '[genre=newsletter:[4,7],novel:[4,5];size=4:[5,6],5:[1,1],6:[1,2],8:[1,3]]'.
     ']'.
     '[values=total:[size:[sum:39,freq:8,min:4,max:8,avg:4.875]]]'.
   ']',
   'Result stringification');

is($node_query->compile->inflate($index->dict)->to_string,
   '[aggr='.
     '[length=total:[avg:2,freq:12,min:2,max:2,sum:24]]' .
     '[freq=total:[8,12]]'.
     '[fields=total:'.
       '[genre=newsletter:[4,7],novel:[4,5];size=4:[5,6],5:[1,1],6:[1,2],8:[1,3]]'.
     ']'.
     '[values=total:[size:[sum:39,freq:8,min:4,max:8,avg:4.875]]]'.
   ']'.
   '[matches='.
     '[1:0-2::GQw..A==,4]'.
     '[1:1-3::Gak..wAA,3]'.
     '[3:0-2::Gdw..A==,8]'.
     '[3:2-4::Gdw..A==,8]'.
     '[2:1-3::GhA..A==,5]'.
     '[0:0-2::Gjs..wAA,2]'.
     '[0:4-6::Gjs..wAA,2]'.
     '[0:6-8::Gjs..wAA,2]'.
     '[3:1-3::Gm4..AA=,7]'.
     '[0:0-2::Gs4..wAA,1]'.
     '[0:2-4::Gs4..wAA,1]'.
     '[2:0-2::G8E..wAA,6]'.
   ']',
   'Stringification');


# Run merge query
$koral = Krawfish::Koral->new;
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
  $mb->aggregate(
    $mb->a_fields(qw/genre size/)
  ),
  $mb->group_by(
    $mb->g_fields(qw/genre size/)
  )
);

ok($cluster_q = $koral->to_segments, 'To cluster query');

is($cluster_q->to_string,
   "node(k=100:gFields('genre','size':aggr(fields:['genre','size']:filter((aabb)|(aacc),[1]))))",
   'stringification');

$node_q = $cluster_q->identify($index->dict);

is($node_q->to_string(1),
   'node(k=100:gFields(#3,#7:aggr(fields:[#3,#7]:filter((#10#12)|(#10#14),[1]))))',
   'Stringification');

ok($node_query = $node_q->optimize($index->segments), 'Optimize');

is($node_query->group->inflate($index->dict)->to_string,
   "[group=".
     "[fields=['genre','size'];".
       "total:[".
         "'newsletter_4':[2,3],".
         "'newsletter_5':[1,1],".
         "'newsletter_8':[1,3],".
         "'novel_4':[3,3],".
         "'novel_6':[1,2]".
       "]".
     "]".
   "]",
   'Collect group');

is($node_query->compile->inflate($index->dict)->to_string,
   "[aggr=".
     "[fields=".
       "total:[".
         "genre=newsletter:[4,7],novel:[4,5];".
         "size=4:[5,6],5:[1,1],6:[1,2],8:[1,3]".
       "]".
     "]".
   "]".
   "[group=".
     "[fields=['genre','size'];".
       "total:[".
         "'newsletter_4':[2,3],".
         "'newsletter_5':[1,1],".
         "'newsletter_8':[1,3],".
         "'novel_4':[3,3],".
         "'novel_6':[1,2]".
       "]".
     "]".
   "]",
   'Full compilation');


done_testing;
__END__

