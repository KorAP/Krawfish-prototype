use Test::More;
use Test::Krawfish;
use Data::Dumper;
use strict;
use warnings;

use_ok('Krawfish::Index');
use_ok('Krawfish::Koral');

# Create some documents
my $index = Krawfish::Index->new;

ok($index->introduce_field('id', 'NUM'), 'Introduce field as sortable');
ok($index->introduce_field('author', 'DE'), 'Introduce field as sortable');
ok($index->introduce_field('genre', 'DE'), 'Introduce field as sortable');
ok($index->introduce_field('title', 'DE'), 'Introduce field as sortable');

ok_index($index, {
  id => 2,
  author => 'Peter',
  genre => 'novel',
  age => 4
} => [qw/aa bb/], 'Add complex document');
ok_index($index, {
  id => 3,
  author => 'Julian',
  genre => 'novel',
  age => 3
} => [qw/bb/], 'Add complex document');
ok_index($index, {
  id => 1,
  author => 'Abraham',
  genre => 'newsletter',
  title => 'Your way to success!',
  age => 4
} => [qw/aa bb aa/], 'Add complex document');
ok_index($index, {
  id => 6,
  author => 'Fritz',
  genre => 'newsletter',
  age => 3
} => [qw/aa bb/], 'Add complex document');
ok_index($index, {
  id => 5,
  author => 'Michael',
  genre => 'newsletter',
  title => 'Your new way to success!',
  age => 7
} => [qw/aa bb/], 'Add complex document');

ok($index->commit, 'Commit data');

my $koral = Krawfish::Koral->new;
my $qb = $koral->query_builder;
my $mb = $koral->compilation_builder;
my ($query, $result, $clone);


$koral->query(
  $qb->seq(
    $qb->token('aa'),
    $qb->token('bb')
  )
);

ok($query = $koral->to_query->identify($index->dict)->optimize($index->segment), 'optimize');

is($query->to_string, 'constr(pos=2:#11,filter(#13,[1]))', 'Stringification');

# Check normal search
matches($query, ['[0:0-2]','[2:0-2]','[3:0-2]','[4:0-2]'], 'Query');

# Sort by id
$koral->compilation(
  $mb->sort_by(
    $mb->s_field('id')
  )
);

ok($query = $koral->to_query, 'Normalize');

ok($query = $query->identify($index->dict)->optimize($index->segment), 'optimize');

is($query->to_string,
   'sort(field=#1<:bundleDocs(constr(pos=2:#11,filter(#13,[1]))))',
   'Stringification');


# The bundle is: fieldBundle(docBundle(match()))
# '[2:0-2]','[0:0-2]','[4:0-2]','[3:0-2]'
ok($query->next_bundle, 'Move to next bundle');
is($query->current_bundle->to_string, '[[[2:0-2]::1]]', 'Stringification');
ok($query->next_bundle, 'Move to next bundle');
is($query->current_bundle->to_string, '[[[0:0-2]::2]]', 'Stringification');
ok($query->next_bundle, 'Move to next bundle');
is($query->current_bundle->to_string, '[[[4:0-2]::4]]', 'Stringification');
ok($query->next_bundle, 'Move to next bundle');
is($query->current_bundle->to_string, '[[[3:0-2]::5]]', 'Stringification');
ok(!$query->next_bundle, 'No more next bundle');


# New query - sort by author
$koral = Krawfish::Koral->new;
$qb = $koral->query_builder;
$mb = $koral->compilation_builder;

$koral->query(
  $qb->seq(
    $qb->token('aa'),
    $qb->token('bb')
  )
);

$koral->compilation(
  $mb->sort_by(
    $mb->s_field('author')
  )
);

# Check for multiple fields in order
ok($query = $koral->to_query, 'Normalize');

is($query->to_string,
   "sort(field='id'<:sort(field='author'<:filter(aabb,[1])))",
   'Stringification');

ok($query = $query->identify($index->dict), 'Identify');

is($query->to_string(1),
   'sort(field=#1<:sort(field=#2<:filter(#11#13,[1])))',
   'Stringification');

ok($query = $query->optimize($index->segment), 'Optimize');

is($query->to_string,
   'sort(field=#1<,l=1:sort(field=#2<:bundleDocs(constr(pos=2:#11,filter(#13,[1])))))',
   'Stringification');

# 0:Peter, 1:Julian!, 2:Abraham, 3:Fritz, 4:Michael
# 2, 3, 4, 0
# The bundle is: fieldBundle(docBundle(match()))
# The second level is unranked
ok($query->next_bundle, 'Move to next bundle');
is($query->current_bundle->to_string, '[[[2:0-2]::1]]', 'Stringification');
ok($query->next_bundle, 'Move to next bundle');
is($query->current_bundle->to_string, '[[[3:0-2]::2]]', 'Stringification');
ok($query->next_bundle, 'Move to next bundle');
is($query->current_bundle->to_string, '[[[4:0-2]::4]]', 'Stringification');
ok($query->next_bundle, 'Move to next bundle');
is($query->current_bundle->to_string, '[[[0:0-2]::5]]', 'Stringification');
ok(!$query->next_bundle, 'No more next bundle');



# Add to more documents
# 5
ok_index($index, {
  id => 8,
  author => 'Fritz'
} => [qw/aa bb/], 'Add complex document');
# 6
ok_index($index, {
  id => 9,
  author => 'Michael'
} => [qw/aa bb/], 'Add complex document');
# 7
ok_index($index, {
  id => 7,
  author => 'Michael'
} => [qw/aa bb aa bb aa/], 'Add complex document');

ok($index->commit, 'Commit data');

# New query - sort by author
$koral = Krawfish::Koral->new;
$qb = $koral->query_builder;
$mb = $koral->compilation_builder;

$koral->query(
  $qb->seq(
    $qb->token('aa'),
    $qb->token('bb')
  )
);

$koral->compilation(
  $mb->sort_by(
    $mb->s_field('author')
  )
);

# Check for multiple fields in order
ok($query = $koral->to_query->identify($index->dict)->optimize($index->segment), 'Optimize');

is($query->to_string,
   'sort(field=#1<,l=1:sort(field=#2<:bundleDocs(constr(pos=2:#11,filter(#13,[1])))))',
   'Stringification');


# 0:Peter, 1:Julian, 2:Abraham, 3:Fritz, 4:Michael,
# 5:Fritz, 6:Michael, 7:Michael
# Abraham:1:[2];Fritz:2:[3,5];Julian:3:[1];Michael:4:[4,6,7];Peter:5:[0]
# Ranks? [5][3][1][2][4][2][4][4]
# Rank:  [6][3][1][2][5][2][5][4]
# Rank:  [6][3][1][2][4][2][4][5]

#
# 2, [3, 5], [4,7,6], 0
# 0:2, 1:3, 2:1, 3:6, 4:5, 5:8, 6:9, 7:7
#

# List is id => doc_id
# <1:2;2:0;3:1;5:4;6:3;7:7;8:5;9:6>
# [2][3][1][5][4][7][8][6]
#     5,7    4,6,8


ok($query->next_bundle, 'Move to next bundle');
is($query->current_bundle->to_string, '[[[2:0-2]::1]]', 'Stringification');
ok($query->next_bundle, 'Move to next bundle');
is($query->current_bundle->to_string, '[[[3:0-2]::2,5]]', 'Stringification');
ok($query->next_bundle, 'Move to next bundle');
is($query->current_bundle->to_string, '[[[5:0-2]::2,7]]', 'Stringification');
ok($query->next_bundle, 'Move to next bundle');
is($query->current_bundle->to_string, '[[[4:0-2]::4,4]]', 'Stringification');
ok($query->next_bundle, 'Move to next bundle');
is($query->current_bundle->to_string, '[[[7:0-2]|[7:2-4]::4,6]]', 'Stringification');
ok($query->next_bundle, 'Move to next bundle');
is($query->current_bundle->to_string, '[[[6:0-2]::4,8]]', 'Stringification');
ok($query->next_bundle, 'Move to next bundle');
is($query->current_bundle->to_string, '[[[0:0-2]::5]]', 'Stringification');
ok(!$query->next_bundle, 'No more next bundles');



$koral = Krawfish::Koral->new;
$koral->query($qb->seq($qb->token('aa'),$qb->token('bb')));
$koral->compilation($mb->sort_by($mb->s_field('author')));

ok($query = $koral->to_query, 'To query');

# Run query
ok($query = $query->identify($index->dict)->optimize($index->segment), 'Optimize');

ok($clone = $query->clone, 'Clone query');

# 2, [3, 5], [4,7,7,6], 0
ok($query->next, 'Move to next bundle');
is($query->current->to_string, '[2:0-2::1]', 'Stringification');
ok($query->next, 'Move to next bundle');
is($query->current->to_string, '[3:0-2::2,5]', 'Stringification');
ok($query->next, 'Move to next bundle');
is($query->current->to_string, '[5:0-2::2,7]', 'Stringification');
ok($query->next, 'Move to next bundle');
is($query->current->to_string, '[4:0-2::4,4]', 'Stringification');
ok($query->next, 'Move to next bundle');
is($query->current->to_string, '[7:0-2::4,6]', 'Stringification');
ok($query->next, 'Move to next bundle');
is($query->current->to_string, '[7:2-4::4,6]', 'Stringification');
ok($query->next, 'Move to next bundle');
is($query->current->to_string, '[6:0-2::4,8]', 'Stringification');
ok($query->next, 'Move to next bundle');
is($query->current->to_string, '[0:0-2::5]', 'Stringification');
ok(!$query->next, 'No more next bundles');


# Run clone
ok($result = $clone->compile->inflate($index->dict), 'Run clone');

is($result->to_string,
   '[matches=[2:0-2::*,*][3:0-2::*,*][5:0-2::*,*][4:0-2::*,*]'.
     '[7:0-2::*,*][7:2-4::*,*][6:0-2::*,0][0:0-2::*,*]]',
   'Stringification');


# Check with non-ranked sorting field (title)
$koral = Krawfish::Koral->new;
$koral->query(
  $qb->bool_or(
    $qb->token('aa'),
    $qb->token('bb')
  )
);
$koral->compilation(
  $mb->sort_by($mb->s_field('genre')),
  $mb->sort_by($mb->s_field('title'))
);

ok($query = $koral->to_query->identify($index->dict)->optimize($index->segment), 'Optimize');
is($query->to_string,
   'sort(field=#1<,l=2:sort(field=#4<,l=1:sort(field=#3<:bundleDocs(filter(or(#13,#11),[1])))))',
   'Stringification');

# genre,title,id
# newsletter: 2=3=4 -> title: 4,2,3 -> id: irrelevant
# novel: 0,1 -> title: - -> id: 0,1
# -: 5=6=7 -> title: 5=6=7 -> id: 5,6,7
# Finally:
# [4,2,3,0,1,7,5,6]

ok($result = $query->compile->inflate($index->dict), 'Run clone');
is($result->to_string,
   '[matches=[4:0-1::*,*,*][4:1-2::*,*,*][2:0-1::*,*,*][2:1-2::*,*,*][2:2-3::*,*,*][3:0-1::*,*,*][3:1-2::*,*,*][0:0-1::*,*,*][0:1-2::*,*,*][1:0-1::*,*,*][7:0-1::*,*,*][7:1-2::*,*,*][7:2-3::*,*,*][7:3-4::*,*,*][7:4-5::*,*,*][5:0-1::*,*,*][5:1-2::*,*,*][6:0-1::*,*,0][6:1-2::*,*,0]]',
   'Stringification');


diag 'Add sorting criteria in unbundling phase';

done_testing;
__END__
