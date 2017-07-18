use strict;
use warnings;
use Test::Krawfish;
use Test::More;

use_ok('Krawfish::Index');
use_ok('Krawfish::Koral::Query::Builder');

my $index = Krawfish::Index->new;
ok_index($index, '[aa|aa][bb|bb]', 'Add complex document');

my $qb = Krawfish::Koral::Query::Builder->new;

my $wrap = $qb->constraints(
  [$qb->c_position('precedesDirectly')],
  $qb->token('aa'),
  $qb->token('bb')
);

is($wrap->to_string, "constr(pos=precedesDirectly:[aa],[bb])", 'Query is valid');
ok($wrap = $wrap->normalize->finalize, 'Normalization');
is($wrap->to_string, "constr(pos=precedesDirectly:aa,bb)", 'Query is valid');
ok($wrap = $wrap->optimize($index), 'Optimization');
is($wrap->to_string, "constr(pos=2:'aa','bb')", 'Query is valid');
matches($wrap, [qw/[0:0-2] [0:0-2] [0:0-2] [0:0-2]/]);


# From t/query/positions.t

$index = Krawfish::Index->new;
ok_index($index, [qw/aa bb aa bb/], 'Add new document');
ok($wrap = $qb->constraints(
  [$qb->c_position('precedesDirectly')],
  $qb->token('aa'),
  $qb->token('bb')
), 'Sequence');

ok(my $seq = $wrap->normalize->finalize->optimize($index), 'Optimization');

# ok(my $seq = $wrap->plan_for($index), 'Rewrite');
matches($seq, [qw/[0:0-2] [0:2-4]/]);


# Reset index - situation [aa]..[bb] -> [aa][bb]
$index = Krawfish::Index->new;
ok_index($index, '[aa][cc][aa][bb]', 'Add complex document');
ok($qb = Krawfish::Koral::Query::Builder->new, 'Create Koral::Builder');
ok($wrap = $qb->constraints(
  [$qb->c_position('precedesDirectly')],
  $qb->token('aa'),
  $qb->token('bb')
), 'Sequence');
ok($seq = $wrap->normalize->finalize->optimize($index), 'Rewrite');
matches($seq, [qw/[0:2-4]/]);


# Reset index - situation [bb][aa] -> [aa][bb]
$index = Krawfish::Index->new;
ok_index($index, '[bb][aa][bb][aa]', 'Add complex document');
ok($qb = Krawfish::Koral::Query::Builder->new, 'Create Koral::Builder');
ok($wrap = $qb->constraints(
  [$qb->c_position('precedesDirectly')],
  $qb->token('aa'),
  $qb->token('bb')
), 'Sequence');
ok($seq = $wrap->normalize->finalize->optimize($index), 'Rewrite');
matches($seq, [qw/[0:1-3]/]);


# Reset index - situation [aa]..[bb] -> [aa][bb]
$index = Krawfish::Index->new;
ok_index($index,'[aa][cc][aa][bb]', 'Add complex document');
ok($qb = Krawfish::Koral::Query::Builder->new, 'Create Koral::Builder');
ok($wrap = $qb->position(['precedesDirectly'],$qb->token('aa'), $qb->token('bb')), 'Sequence');
ok($seq = $wrap->normalize->finalize->optimize($index), 'Rewrite');
matches($seq, [qw/[0:2-4]/]);




# Reset index - situation [bb]..[aa] -> [aa][bb]
$index = Krawfish::Index->new;
ok_index($index,'[bb][cc][aa][bb]', 'Add complex document');
ok($qb = Krawfish::Koral::Query::Builder->new($index), 'Create Koral::Builder');
ok($wrap = $qb->constraints(
  [$qb->c_position('precedesDirectly')],
  $qb->token('aa'),
  $qb->token('bb')
), 'Sequence');
ok($seq = $wrap->normalize->finalize->optimize($index), 'Rewrite');
matches($seq, [qw/[0:2-4]/]);




# Multiple matches
# Reset index - situation [bb]..[aa] -> [aa][bb]
$index = Krawfish::Index->new;
ok_index($index,'[aa|aa][bb|bb]', 'Add complex document');
ok($qb = Krawfish::Koral::Query::Builder->new, 'Create Koral::Builder');
ok($wrap = $qb->constraints(
  [$qb->c_position('precedesDirectly')],
  $qb->token('aa'),
  $qb->token('bb')
), 'Sequence');
ok($seq = $wrap->normalize->finalize->optimize($index), 'Rewrite');
matches($seq, [qw/[0:0-2] [0:0-2] [0:0-2] [0:0-2]/]);




# Reset index
$index = Krawfish::Index->new;
ok_index($index, '[aa][bb|bb]', 'Add complex document');
ok($qb = Krawfish::Koral::Query::Builder->new, 'Create Koral::Builder');
ok($wrap = $qb->constraints(
  [$qb->c_position('precedesDirectly')],
  $qb->token('aa'),
  $qb->token('bb')
), 'Sequence');
ok($seq = $wrap->normalize->finalize->optimize($index), 'Rewrite');
# query language: [aa][bb]
matches($seq, [qw/[0:0-2] [0:0-2]/]);


# Reset index
$index = Krawfish::Index->new;
ok_index($index, '[aa|aa][bb]', 'Add complex document');
ok($qb = Krawfish::Koral::Query::Builder->new($index), 'Create Koral::Builder');
ok($wrap = $qb->constraints(
  [$qb->c_position('precedesDirectly')],
  $qb->token('aa'),
  $qb->token('bb')
), 'Sequence');
ok($seq = $wrap->normalize->finalize->optimize($index), 'Rewrite');
matches($seq, [qw/[0:0-2] [0:0-2]/]);



# Reset index
$index = Krawfish::Index->new;
ok_index($index, '[aa|aa][bb|bb][aa|aa][bb|bb]', 'Add complex document');
ok($qb = Krawfish::Koral::Query::Builder->new, 'Create Koral::Builder');
ok($wrap = $qb->constraints(
  [$qb->c_position('precedesDirectly')],
  $qb->token('aa'),
  $qb->token('bb')
), 'Sequence');
ok($seq = $wrap->normalize->finalize->optimize($index), 'Rewrite');
matches($seq, [qw/[0:0-2] [0:0-2] [0:0-2] [0:0-2] [0:2-4] [0:2-4] [0:2-4] [0:2-4]/]);




# Reset index
$index = Krawfish::Index->new;
ok_index($index, '[aa|aa][bb|bb][aa|aa][bb|bb]', 'Add complex document');
ok_index($index, '[aa]', 'Add complex document');
ok_index($index, '[bb]', 'Add complex document');
ok_index($index, '[aa|aa][bb|bb][aa|aa][bb|bb]', 'Add complex document');
ok($qb = Krawfish::Koral::Query::Builder->new, 'Create Koral::Builder');
ok($wrap = $qb->constraints(
  [$qb->c_position('precedesDirectly')],
  $qb->token('aa'),
  $qb->token('bb')
), 'Sequence');
ok($seq = $wrap->normalize->finalize->optimize($index), 'Rewrite');
matches($seq, [
  qw/[0:0-2] [0:0-2] [0:0-2] [0:0-2] [0:2-4] [0:2-4] [0:2-4] [0:2-4]/,
  qw/[3:0-2] [3:0-2] [3:0-2] [3:0-2] [3:2-4] [3:2-4] [3:2-4] [3:2-4]/
]);



## Overlap
$index = Krawfish::Index->new;
ok_index($index, '[aa|bb][aa|bb][aa|bb][aa|bb]', 'Add new document');
ok($wrap = $qb->position(
  ['overlapsLeft'],
  $qb->class($qb->repeat($qb->token('aa'), 1, undef),1),
  $qb->class($qb->repeat($qb->token('bb'), 1, undef),2)
), 'Sequence');

is($wrap->to_string, 'constr(pos=overlapsLeft:{1:[aa]+},{2:[bb]+})', 'Stringification');
ok($wrap = $wrap->normalize->finalize, 'Rewrite');
is($wrap->to_string, 'constr(pos=overlapsLeft:{1:aa{1,100}},{2:bb{1,100}})',
   'Stringification');
ok(my $ov = $wrap->optimize($index), 'Optimization');
is($ov->to_string, "constr(pos=4:class(1:rep(1-100:'aa')),class(2:rep(1-100:'bb')))",
   'Stringification');


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


TODO: {
  local $TODO = 'Test further';
};


done_testing;
__END__
