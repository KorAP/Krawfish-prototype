use strict;
use warnings;
use Test::Krawfish;
use Test::More;

use_ok('Krawfish::Index');
use_ok('Krawfish::Koral::Query::Builder');

my $index = Krawfish::Index->new;
ok_index($index, [qw/aa bb aa bb aa bb/], 'Add complex document');

my $qb = Krawfish::Koral::Query::Builder->new;

# This equals to [aa][]{1,4}[bb]
my $wrap = $qb->constraints(
  [$qb->c_position('precedes', 'precedesDirectly'), $qb->c_in_between(1,4)],
  $qb->token('aa'),
  $qb->token('bb')
);

is($wrap->to_string, "constr(pos=precedes;precedesDirectly,between=1-4:[aa],[bb])", 'Query is valid');
ok(my $query = $wrap->normalize->optimize($index), 'Optimize');
is($query->to_string, "constr(pos=3,between=1-4:'aa','bb')", 'Query is valid');
matches($query, ['[0:0-4]','[0:0-6]','[0:2-6]']);

# This equals to [aa][]{1,3}[bb]
$wrap = $qb->constraints(
  [$qb->c_position('precedes', 'precedesDirectly'), $qb->c_in_between(1,3)],
  $qb->token('aa'),
  $qb->token('bb')
);

is($wrap->to_string, "constr(pos=precedes;precedesDirectly,between=1-3:[aa],[bb])", 'Query is valid');
ok($query = $wrap->normalize->optimize($index), 'Optimize');
is($query->to_string, "constr(pos=3,between=1-3:'aa','bb')", 'Query is valid');
matches($query, ['[0:0-4]','[0:2-6]']);


# This equals to [aa][]{1,3}[bb] - optimized
$wrap = $qb->constraints(
  [$qb->c_position('precedes'), $qb->c_in_between(1,3)],
  $qb->token('aa'),
  $qb->token('bb')
);

is($wrap->to_string, "constr(pos=precedes,between=1-3:[aa],[bb])", 'Query is valid');
ok($query = $wrap->normalize->optimize($index), 'Optimize');
is($query->to_string, "constr(pos=1,between=1-3:'aa','bb')", 'Query is valid');
matches($query, ['[0:0-4]','[0:2-6]']);



# This equals to [aa][]{1,3}[bb] - but is contradicted due to precedesDirectly!
$wrap = $qb->constraints(
  [$qb->c_position('precedesDirectly'), $qb->c_in_between(1,3)],
  $qb->token('aa'),
  $qb->token('bb')
);

is($wrap->to_string, "constr(pos=precedesDirectly,between=1-3:[aa],[bb])", 'Query is valid');
ok($query = $wrap->normalize->optimize($index), 'Optimize');

# TODO: This may be optimized away
is($query->to_string, "constr(pos=2,between=1-3:'aa','bb')", 'Query is valid');
matches($query, []);


done_testing;
__END__
