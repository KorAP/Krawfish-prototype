use strict;
use warnings;
use Test::Krawfish;
use Test::More;

use_ok('Krawfish::Index');
use_ok('Krawfish::Koral::Query::Builder');

my $index = Krawfish::Index->new;
ok_index($index, '[aa|xx][cc][bb|xx]', 'Add complex document');
ok_index($index, '[aa|xx][dd][bb|xx]', 'Add complex document');
ok_index($index, '[aa|xx][cc][bb|xx]', 'Add complex document');

my $qb = Krawfish::Koral::Query::Builder->new;

my $query = $qb->constraint(
  [
    $qb->c_position('precedes'),
    $qb->c_not_between($qb->token('cc'))
  ],
  $qb->token('aa'),
  $qb->token('bb')
);

is($query->to_string, 'constr(pos=precedes,notBetween=[cc]:[aa],[bb])', 'Stringification');

ok(my $plan = $query->normalize->finalize->identify($index->dict)->optimize($index->segment), 'Planning');

# is($plan->to_string, "constr(pos=1,between=1-1,notBetween=#3:#2,#7)", 'Query is valid');

matches($plan, [qw/[1:0-3]/]);

# New query
$query = $qb->constraint(
  [
    $qb->c_position('precedes'),
    $qb->c_not_between($qb->token('dd'))
  ],
  $qb->token('xx'),
  $qb->token('xx')
);

is($query->to_string, 'constr(pos=precedes,notBetween=[dd]:[xx],[xx])', 'Stringification');

ok($plan = $query->normalize->finalize->identify($index->dict)->optimize($index->segment), 'Planning');

# is($plan->to_string, "constr(pos=1,between=1-1,notBetween=#5:#3,#3)", 'Query is valid');

matches($plan, [qw/[0:0-3] [2:0-3]/]);

# Ignore classes in negation
$query = $qb->constraint(
  [
    $qb->c_position('precedes'),
    $qb->c_not_between($qb->class($qb->token('dd')))
  ],
  $qb->token('xx'),
  $qb->token('xx')
);

is($query->to_string, 'constr(pos=precedes,notBetween={1:[dd]}:[xx],[xx])', 'Stringification');
ok($plan = $query->normalize->finalize->identify($index->dict)->optimize($index->segment), 'Planning');

# is($plan->to_string, "constr(pos=1,between=1-1,notBetween=#9,class=1:#3,#3)", 'Query is valid');

# TODO:
#   check matches

# Introduce classes inbetween
$query = $qb->constraint(
  [
    $qb->c_position('precedes'),
    $qb->c_not_between($qb->token('dd')),
    $qb->c_class_distance
  ],
  $qb->token('xx'),
  $qb->token('xx')
);

is($query->to_string, 'constr(pos=precedes,notBetween=[dd],class=1:[xx],[xx])', 'Stringification');
ok($plan = $query->normalize->finalize->identify($index->dict)->optimize($index->segment), 'Planning');
# is($plan->to_string, "constr(pos=1,between=1-1,notBetween=#9,class=1:#3,#3)", 'Query is valid');

# TODO:
#   check matches



# Ignore no-match in negation
$query = $qb->constraint(
  [
    $qb->c_position('precedes'),
    $qb->c_not_between($qb->class($qb->token('ff')))
  ],
  $qb->token('xx'),
  $qb->token('xx')
);

is($query->to_string, 'constr(pos=precedes,notBetween={1:[ff]}:[xx],[xx])', 'Stringification');
ok($plan = $query->normalize->finalize->identify($index->dict)->optimize($index->segment), 'Planning');
# is($plan->to_string, "constr(pos=1,between=1-1,class=1:#3,#3)", 'Query is valid');

# TODO:
#   Check matches


TODO: {
  local $TODO = 'Further testing with repetitions at the beginning and inbetween - and buffers!';
};


done_testing;
__END__


