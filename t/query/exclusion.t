use Test::More;
use Test::Krawfish;
use strict;
use warnings;

$|++;

# Text exclusion with
# Frames: 'isAround', 'startsWith', 'endsWith', 'matches'

use_ok('Krawfish::Koral::Query::Builder');
use_ok('Krawfish::Index');

my $index = Krawfish::Index->new;
my $qb = Krawfish::Koral::Query::Builder->new;
my ($wrap, $query);

$query = $qb->exclusion(
  [qw/isAround startsWith endsWith matches/],
  $qb->span('aa'),
  $qb->token('bb')
);
is($query->to_string, 'excl(432:<aa>,[bb])', 'Stringification');

{

# Exclusion planning
ok_index($index, '<1:aa>[bb][bb]</1><2:aa>[cc]</2>', 'Add complex document');

ok($wrap = $query->plan_for($index), 'Planning');
is($wrap->to_string, "excl(432:'<>aa','bb')",
   'Planned Stringification');

ok($wrap->next, 'Init');
is($wrap->current->to_string, '[0:2-3]', 'Match');
ok(!$wrap->next, 'No more');
}

# New index - same query
$index = Krawfish::Index->new;
ok_index($index, '<1:aa>[bb][bb]</1><2:aa><3:aa>[cc]</3>[bb]</2>', 'Add complex document');
ok_index($index, '<1:aa>[dd]</1><2:aa>[dd][bb]</2><3:aa>[dd]</3>', 'Add complex document');


ok($wrap = $query->plan_for($index), 'Planning');
is($wrap->to_string, "excl(432:'<>aa','bb')",
   'Planned Stringification');


ok($wrap->next, 'Init');
is($wrap->current->to_string, '[0:2-3]', 'Match');
ok($wrap->next, 'No more');
is($wrap->current->to_string, '[1:0-1]', 'Match');
ok($wrap->next, 'No more');
is($wrap->current->to_string, '[1:3-4]', 'Match');
ok(!$wrap->next, 'No more');

# New index - same query
$index = Krawfish::Index->new;
ok_index($index, '<1:aa>[bb][bb]</1><2:aa><3:aa>[cc]</3>[bb]</2>', 'Add complex document');
ok_index($index, '<1:aa>[dd]</1><2:aa>[dd][bb]</2><3:aa>[dd]</3>', 'Add complex document');

 {
ok($wrap = $query->plan_for($index), 'Planning');
is($wrap->to_string, "excl(432:'<>aa','bb')",
   'Planned Stringification');

ok($wrap->next, 'Init');
is($wrap->current->to_string, '[0:2-3]', 'Match');
ok($wrap->next, 'No more');
is($wrap->current->to_string, '[1:0-1]', 'Match');
ok($wrap->next, 'No more');
is($wrap->current->to_string, '[1:3-4]', 'Match');
ok(!$wrap->next, 'No more');
}


# Query only excludes startsWith
# Means: Find a <aa> that does not start with [bb]
# TODO:
#   This should be optimized - the buffer is allowed to forget
#   WAY earlier!
$query = $qb->exclusion(
  [qw/startsWith/],
  $qb->span('aa'),
  $qb->token('bb')
);
is($query->to_string, 'excl(16:<aa>,[bb])', 'Stringification');

ok($wrap = $query->plan_for($index), 'Planning');
is($wrap->to_string, "excl(16:'<>aa','bb')",
   'Planned Stringification');

ok($wrap->next, 'Init');
is($wrap->current->to_string, '[0:2-3]', 'Match');
ok($wrap->next, 'more');
is($wrap->current->to_string, '[0:2-4]', 'Match');
ok($wrap->next, 'more');
is($wrap->current->to_string, '[1:0-1]', 'Match');
ok($wrap->next, 'more');
is($wrap->current->to_string, '[1:1-3]', 'Match');
ok($wrap->next, 'more');
is($wrap->current->to_string, '[1:3-4]', 'Match');
ok(!$wrap->next, 'No more');




done_testing;
__END__
