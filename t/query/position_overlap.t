use Test::More;
use Test::Krawfish;
use strict;
use warnings;

use_ok('Krawfish::Index');
use_ok('Krawfish::Koral::Query::Builder');

my $index = Krawfish::Index->new;

ok_index($index, '[aa|bb][aa|bb][aa|bb][aa|bb]', 'Add new document');

ok(my $qb = Krawfish::Koral::Query::Builder->new, 'Create Koral::Builder');

ok(my $wrap = $qb->position(
  ['overlapsLeft'],
  $qb->class($qb->repeat($qb->token('aa'), 1, undef),1),
  $qb->class($qb->repeat($qb->token('bb'), 1, undef),2)
), 'Sequence');

is($wrap->to_string, 'pos(4:{1:[aa]+},{2:[bb]+})', 'Stringification');
ok(my $ov = $wrap->plan_for($index), 'Rewrite');
is($ov->to_string, "constr(pos=4:class(1:rep(1-100:'aa')),class(2:rep(1-100:'bb')))", 'Stringification');


# [<0  {1> 2}] 3
# [<0  {1> 2   3}]
# [<0  {1  2>  3}]
# [<0   1 {2>  3}]
#   0 [<1 {2>  3}]

ok($ov->next, 'Init');
is($ov->current->to_string, '[0:0-3$0,1,0,2|0,2,1,3]', 'Match');
ok($ov->next, 'More');
is($ov->current->to_string, '[0:0-4$0,1,0,2|0,2,1,4]', 'Match');
ok($ov->next, 'More');
is($ov->current->to_string, '[0:0-4$0,1,0,3|0,2,1,4]', 'Match');
ok($ov->next, 'More');
is($ov->current->to_string, '[0:0-4$0,1,0,3|0,2,2,4]', 'Match');
ok($ov->next, 'More');
is($ov->current->to_string, '[0:1-4$0,1,1,3|0,2,2,4]', 'Match');
ok(!$ov->next, 'No More');

done_testing;
__END__
