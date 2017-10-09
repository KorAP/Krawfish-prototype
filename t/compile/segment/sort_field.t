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
  age => 7
} => [qw/aa bb/], 'Add complex document');

ok($index->commit, 'Commit data');

my $koral = Krawfish::Koral->new;
my $qb = $koral->query_builder;
my $mb = $koral->compile_builder;
my $query;


$koral->query(
  $qb->seq(
    $qb->token('aa'),
    $qb->token('bb')
  )
);

ok($query = $koral->to_query->identify($index->dict)->optimize($index->segment), 'optimize');

is($query->to_string, 'constr(pos=2:#10,filter(#12,[1]))', 'Stringification');

# Check normal search
matches($query, ['[0:0-2]','[2:0-2]','[3:0-2]','[4:0-2]'], 'Query');

# Sort by id
$koral->compile(
  $mb->sort_by(
    $mb->s_field('id')
  )
);

ok($query = $koral->to_query, 'Normalize');

ok($query = $query->identify($index->dict)->optimize($index->segment), 'optimize');

is($query->to_string,
   'sort(field=#1<,0-5:bundleDocs(constr(pos=2:#10,filter(#12,[1]))))',
   'Stringification');


# '[2:0-2]','[0:0-2]','[4:0-2]','[3:0-2]'
ok($query->next_bundle, 'Move to next bundle');

# The bundle is: fieldBundle(docBundle(match()))
is($query->current_bundle->to_string, '[[[2:0-2]]]', 'Stringification');
ok($query->next_bundle, 'Move to next bundle');
is($query->current_bundle->to_string, '[[[0:0-2]]]', 'Stringification');
ok($query->next_bundle, 'Move to next bundle');
is($query->current_bundle->to_string, '[[[4:0-2]]]', 'Stringification');
ok($query->next_bundle, 'Move to next bundle');
is($query->current_bundle->to_string, '[[[3:0-2]]]', 'Stringification');
ok(!$query->next_bundle, 'No more next bundle');

# New query - sort by author
$koral = Krawfish::Koral->new;
$qb = $koral->query_builder;
$mb = $koral->compile_builder;

$koral->query(
  $qb->seq(
    $qb->token('aa'),
    $qb->token('bb')
  )
);

$koral->compile(
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

is($query->to_string,
   'sort(field=#1<:sort(field=#2<:filter(#10#12,[1])))',
   'Stringification');

ok($query = $query->optimize($index->segment), 'Optimize');

is($query->to_string,
   'sort(field=#1<,0-5:sort(field=#2<,0-5:bundleDocs(constr(pos=2:#10,filter(#12,[1])))))',
   'Stringification');

# 0:Peter, 1:Julian!, 2:Abraham, 3:Fritz, 4:Michael
# 2, 3, 4, 0
# The bundle is: fieldBundle(docBundle(match()))
ok($query->next_bundle, 'Move to next bundle');
is($query->current_bundle->to_string, '[[[2:0-2]]]', 'Stringification');
ok($query->next_bundle, 'Move to next bundle');
is($query->current_bundle->to_string, '[[[3:0-2]]]', 'Stringification');
ok($query->next_bundle, 'Move to next bundle');
is($query->current_bundle->to_string, '[[[4:0-2]]]', 'Stringification');
ok($query->next_bundle, 'Move to next bundle');
is($query->current_bundle->to_string, '[[[0:0-2]]]', 'Stringification');
ok(!$query->next_bundle, 'No more next bundle');


# Add to more documents
ok_index($index, {
  id => 8,
  author => 'Fritz'
} => [qw/aa bb/], 'Add complex document');
ok_index($index, {
  id => 9,
  author => 'Michael'
} => [qw/aa bb/], 'Add complex document');
ok_index($index, {
  id => 7,
  author => 'Michael'
} => [qw/aa bb aa bb aa/], 'Add complex document');

ok($index->commit, 'Commit data');


# New query - sort by author
$koral = Krawfish::Koral->new;
$qb = $koral->query_builder;
$mb = $koral->compile_builder;

$koral->query(
  $qb->seq(
    $qb->token('aa'),
    $qb->token('bb')
  )
);

$koral->compile(
  $mb->sort_by(
    $mb->s_field('author')
  )
);

# Check for multiple fields in order
ok($query = $koral->to_query->identify($index->dict)->optimize($index->segment), 'Optimize');

is($query->to_string,
   'sort(field=#1<,0-8:sort(field=#2<,0-8:bundleDocs(constr(pos=2:#10,filter(#12,[1])))))',
   'Stringification');


# 0:Peter, 1:Julian!, 2:Abraham, 3:Fritz, 4:Michael, 5:Fritz, 6:Michael, 7:Michael
# 2, [3, 5], [4,7,6], 0
ok($query->next_bundle, 'Move to next bundle');
is($query->current_bundle->to_string, '[[[2:0-2]]]', 'Stringification');
ok($query->next_bundle, 'Move to next bundle');
is($query->current_bundle->to_string, '[[[3:0-2]]]', 'Stringification');
ok($query->next_bundle, 'Move to next bundle');
is($query->current_bundle->to_string, '[[[5:0-2]]]', 'Stringification');
ok($query->next_bundle, 'Move to next bundle');
is($query->current_bundle->to_string, '[[[4:0-2]]]', 'Stringification');
ok($query->next_bundle, 'Move to next bundle');
is($query->current_bundle->to_string, '[[[7:0-2]|[7:2-4]]]', 'Stringification');
ok($query->next_bundle, 'Move to next bundle');
is($query->current_bundle->to_string, '[[[6:0-2]]]', 'Stringification');
ok($query->next_bundle, 'Move to next bundle');
is($query->current_bundle->to_string, '[[[0:0-2]]]', 'Stringification');
ok(!$query->next_bundle, 'No more next bundles');

$koral->query($qb->seq($qb->token('aa'),$qb->token('bb')));
$koral->compile($mb->sort_by($mb->s_field('author')));
ok($query = $koral->to_query->identify($index->dict)->optimize($index->segment), 'Optimize');

# 2, [3, 5], [4,7,6], 0
print "\n-----------------------------------------\n\n";
ok($query->next, 'Move to next bundle');
is($query->current->to_string, '[2:0-2]', 'Stringification');
ok($query->next, 'Move to next bundle');
is($query->current->to_string, '[3:0-2]', 'Stringification');
ok($query->next, 'Move to next bundle');
is($query->current->to_string, '[5:0-2]', 'Stringification');
ok($query->next, 'Move to next bundle');
is($query->current->to_string, '[4:0-2]', 'Stringification');
ok($query->next, 'Move to next bundle');
is($query->current->to_string, '[7:0-2]', 'Stringification');
ok($query->next, 'Move to next bundle');
is($query->current->to_string, '[7:2-4]', 'Stringification');
ok($query->next, 'Move to next bundle');
is($query->current->to_string, '[6:0-2]', 'Stringification');
ok($query->next, 'Move to next bundle');
is($query->current->to_string, '[0:0-2]', 'Stringification');
ok(!$query->next, 'No more next bundles');


diag 'Test cloning';
diag 'Deal with non-ranked fields';
diag 'Add sorting criteria in unbundling phase';

done_testing;
__END__
