use Test::More;
use strict;
use warnings;

use_ok('Krawfish::Koral::Query::Builder');

my $qb = Krawfish::Koral::Query::Builder->new;

# No constraints
ok(my $query = $qb->constraints(
  [],
  $qb->repeat($qb->term('a'),2),
  $qb->term('b')
), 'Query without a constraint');
is($query->to_string, 'constr(a{2},b)', 'Constraint');
is($query->min_span, 2, 'Span length');
is($query->max_span, -1, 'Span length');
ok($query = $query->normalize, 'Normalize');
is($query->to_string, 'constr(a{2},b)', 'Constraint');
is($query->min_span, 2, 'Span length');
is($query->max_span, -1, 'Span length');


# Position constraint: succeeds_directly
ok($query = $qb->constraints(
  [$qb->c_position('succeedsDirectly')],
  $qb->repeat($qb->term('a'), 2),
  $qb->term('b')
), 'Query without a constraint');
is($query->to_string, 'constr(pos=succeedsDirectly:a{2},b)', 'Constraint');
is($query->min_span, 3, 'Span length');
is($query->max_span, 3, 'Span length');
ok($query = $query->normalize, 'Normalize');
is($query->to_string, 'constr(pos=succeedsDirectly:a{2},b)', 'Constraint');
is($query->min_span, 3, 'Span length');
is($query->max_span, 3, 'Span length');

# Position constraint: precedes
ok($query = $qb->constraints(
  [$qb->c_position('precedes')],
  $qb->repeat($qb->term('a'), 2),
  $qb->term('b')
), 'Query without a constraint');
is($query->to_string, 'constr(pos=precedes:a{2},b)', 'Constraint');
is($query->min_span, 4, 'Span length');
is($query->max_span, -1, 'Span length');
ok($query = $query->normalize, 'Normalize');
is($query->to_string, 'constr(pos=precedes:a{2},b)', 'Constraint');
is($query->min_span, 4, 'Span length');
is($query->max_span, -1, 'Span length');


# Position constraint: overlaps
ok($query = $qb->constraints(
  [$qb->c_position('overlapsLeft', 'overlapsRight')],
  $qb->repeat($qb->term('a'), 2),
  $qb->term('b')
), 'Query without a constraint');
is($query->to_string, 'constr(pos=overlapsLeft;overlapsRight:a{2},b)', 'Constraint');
is($query->min_span, 3, 'Span length');
is($query->max_span, 2, 'Span length');
ok($query = $query->normalize, 'Normalize');
is($query->to_string, '[0]', 'Constraint');
is($query->min_span, -1, 'Span length');
is($query->max_span, -1, 'Span length');


# Position constraint: overlaps
ok($query = $qb->constraints(
  [$qb->c_position('overlapsLeft', 'overlapsRight')],
  $qb->repeat($qb->term('a'), 1, 100),
  $qb->repeat($qb->term('b'), 1, 100)
), 'Query without a constraint');
is($query->to_string, 'constr(pos=overlapsLeft;overlapsRight:a{1,100},b{1,100})', 'Constraint');
is($query->min_span, 2, 'Span length');
is($query->max_span, 199, 'Span length');
ok($query = $query->normalize, 'Normalize');
is($query->to_string, 'constr(pos=overlapsLeft;overlapsRight:a{1,100},b{1,100})', 'Constraint');
is($query->min_span, 2, 'Span length');
is($query->max_span, 199, 'Span length');

# Overlaps with classes
ok($query = $qb->constraints(
  [$qb->c_position('overlapsLeft', 'overlapsRight')],
  $qb->class($qb->repeat($qb->term('a'), 1, undef),3),
  $qb->class($qb->repeat($qb->term('b'), 1, undef),4)
), 'Query without a constraint');
is($query->to_string, 'constr(pos=overlapsLeft;overlapsRight:{3:a+},{4:b+})', 'Constraint');
is($query->min_span, 2, 'Span length');
is($query->max_span, -1, 'Span length');
ok($query = $query->normalize, 'Normalize');
is($query->to_string, 'constr(pos=overlapsLeft;overlapsRight:{3:a{1,100}},{4:b{1,100}})', 'Constraint');
is($query->min_span, 2, 'Span length');
is($query->max_span, -1, 'Span length');


ok($query = $qb->constraints(
  [$qb->c_position('overlapsLeft', 'overlapsRight')],
  $qb->repeat($qb->class($qb->term('a'),3), 1, 100),
  $qb->repeat($qb->class($qb->term('b'),4), 1, 100)
), 'Query without a constraint');
is($query->to_string, 'constr(pos=overlapsLeft;overlapsRight:{3:a}{1,100},{4:b}{1,100})', 'Constraint');
is($query->min_span, 2, 'Span length');
is($query->max_span, 199, 'Span length');
ok($query = $query->normalize, 'Normalize');
is($query->to_string, 'constr(pos=overlapsLeft;overlapsRight:{3:a{1,100}},{4:b{1,100}})', 'Constraint');
is($query->min_span, 2, 'Span length');
is($query->max_span, 199, 'Span length');


TODO: {
  local $TODO = 'Check all constraints';
}


done_testing;

__END__

# 'aa' ({1:[]{2}}|{2:[]{3}|'cc'})+ 'bb'
# Maybe $qb->c_cascade()

# The problem with c_or() is, that payloads may be added, while
# a constraint fails - Means: payloads need to be created onm every branch

$qb->constr(
  $qb->c_rep(
    $qb->c_or(
      $qb->c_and($qb->c_dist(2), $qb->c_class_dist(1)),
      $qb->c_and($qb->c_dist(3), $qb->c_class_dist(2)),
      $qb->c_and($qb->c_dist($qb->token('cc'),1,1), $qb->c_class_dist(2))
    ),
    1,
    undef
  ),
  $qb->token('aa'),
  $qb->token('bb')
)

# constr(frames=precedes,rep=1-100,or():'aa','bb')
# c_rep is problematic!!!
# May be reformulated to:
# 'aa' ({1:[]{2,100,steps=2}}|{2:[]{3,100,steps=3}}) 'bb'| 'aa' {2:'cc'}+ 'bb'


# 'aa' \s+1 'bb'
# Means - aa is in a sentence and bb is in the same or in a next sentence.
$qb->constraint(
  $qb->c_dist($c->span("base/s=s"),1)
  $qb->token('aa'),
  $qb->token('bb')
);

# c_dist(2):
if ($first->end = $second->start + 2) {
  return MATCH
}

# c_dist($query, 2):
if ($first->end == $query->start) {
  $query->end == $second->start) {
  return MATCH;
};
