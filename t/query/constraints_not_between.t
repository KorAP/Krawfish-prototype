use strict;
use warnings;
use Test::Krawfish;
use Test::More;

use_ok('Krawfish::Index');
use_ok('Krawfish::Koral::Query::Builder');

# TODO:
#   Test with buffer!

my $index = Krawfish::Index->new;
ok_index($index, '[aa|xx][cc][bb|xx]', 'Add complex document');
ok_index($index, '[aa|xx][dd][bb|xx]', 'Add complex document');
ok_index($index, '[aa|xx][cc][bb|xx]', 'Add complex document');

my $qb = Krawfish::Koral::Query::Builder->new;

my $query = $qb->constraints(
  [
    $qb->c_position('precedes'),
    $qb->c_not_between($qb->token('cc'))
  ],
  $qb->token('aa'),
  $qb->token('bb')
);

is($query->to_string, 'constr(pos=precedes,notBetween=[cc]:[aa],[bb])', 'Stringification');

ok(my $plan = $query->normalize->finalize->optimize($index), 'Planning');

is($plan->to_string, "constr(notBetween='cc',pos=1:'aa','bb')", 'Query is valid');

matches($plan, [qw/[1:0-3]/]);

done_testing;
__END__

# New query
$query = $qb->constraints(
  [
    $qb->c_position('precedes'),
    $qb->c_not_between($qb->token('dd'))
  ],
  $qb->token('xx'),
  $qb->token('xx')
);

is($query->to_string, 'constr(pos=precedes,notBetween=[dd]:[xx],[xx])', 'Stringification');

ok($plan = $query->plan_for($index), 'Planning');

is($plan->to_string, "constr(pos=1,notBetween='dd':'xx','xx')", 'Query is valid');

matches($plan, [qw/[0:0-3] [2:0-3]/]);



# Ignore classes in negation
$query = $qb->constraints(
  [
    $qb->c_position('precedes'),
    $qb->c_not_between($qb->class($qb->token('dd')))
  ],
  $qb->token('xx'),
  $qb->token('xx')
);

is($query->to_string, 'constr(pos=precedes,notBetween={[dd]}:[xx],[xx])', 'Stringification');

ok($plan = $query->plan_for($index), 'Planning');

is($plan->to_string, "constr(pos=1,notBetween='dd':'xx','xx')", 'Query is valid');



# Ignore no-match in negation
$query = $qb->constraints(
  [
    $qb->c_position('precedes'),
    $qb->c_not_between($qb->class($qb->token('ff')))
  ],
  $qb->token('xx'),
  $qb->token('xx')
);

is($query->to_string, 'constr(pos=precedes,notBetween={[ff]}:[xx],[xx])', 'Stringification');

ok($plan = $query->plan_for($index), 'Planning');

is($plan->to_string, "constr(pos=1:'xx','xx')", 'Query is valid');



diag 'Further testing with repetitions at the beginning and inbetween';



done_testing;
__END__


