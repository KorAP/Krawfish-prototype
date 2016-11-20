use Test::More skip_all => 'No tests defined';

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
