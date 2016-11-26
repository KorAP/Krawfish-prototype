use Test::More;
use Test::Krawfish;
use strict;
use warnings;

use_ok('Krawfish::Index');
use_ok('Krawfish::Koral::Query::Builder');

my $index = Krawfish::Index->new;
ok_index($index, [qw/aa bb aa bb/], 'Add new document');

ok(my $qb = Krawfish::Koral::Query::Builder->new, 'Create QueryBuilder');
ok(my $wrap = $qb->class($qb->token('bb'), 2), 'Class');
is($wrap->to_string, '{2:[bb]}', 'Stringification');
ok(my $class = $wrap->plan_for($index), 'Rewrite');
is($class->to_string, "class(2:'bb')", 'stringification');

ok($class->next, 'More');
is($class->current->to_string, '[0:1-2$0,2,1,2]', 'Match');
ok($class->next, 'More');
is($class->current->to_string, '[0:3-4$0,2,3,4]', 'Match');
ok(!$class->next, 'No More');


# Nest classes
$wrap = $qb->seq(
  $qb->class($qb->token('aa'), 1),
  $qb->class($qb->token('bb'), 2)
);

is($wrap->to_string, '{1:[aa]}{2:[bb]}', 'Stringification');
ok($class = $wrap->plan_for($index), 'Rewrite');
is($class->to_string, "pos(2:class(1:'aa'),class(2:'bb'))", 'stringification');

ok($class->next, 'More');
is($class->current->to_string, '[0:0-2$0,1,0,1|0,2,1,2]', 'Match');
ok($class->next, 'More');
is($class->current->to_string, '[0:2-4$0,1,2,3|0,2,3,4]', 'Match');
ok(!$class->next, 'More');


done_testing;
__END__
