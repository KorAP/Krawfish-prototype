use strict;
use warnings;
use Test::Krawfish;
use Test::More;

use_ok('Krawfish::Index');
use_ok('Krawfish::Koral::Query::Builder');

my $index = Krawfish::Index->new;
ok_index_2($index, [qw/aa bb aa bb aa bb/], 'Add complex document');

my $qb = Krawfish::Koral::Query::Builder->new;

# This equals to [aa]{5:[]+}[bb]
my $wrap = $qb->constraints(
  [$qb->c_position('precedes'), $qb->c_class_distance(5)],
  $qb->token('aa'),
  $qb->token('bb')
);

is($wrap->to_string, "constr(pos=precedes,class=5:[aa],[bb])", 'Query is valid');
ok(my $query = $wrap->normalize->finalize->identify($index->dict)->optimize($index->segment), 'Planning');
# is($query->to_string, "constr(pos=1,class=5:#2,#4)", 'Query is valid');

matches($query, ['[0:0-4$0,5,1,2]','[0:0-6$0,5,1,4]','[0:2-6$0,5,3,4]']);

# This equals to [aa]{5:[]*}[bb]
$wrap = $qb->constraints(
  [$qb->c_position('precedes', 'precedesDirectly'), $qb->c_class_distance(5)],
  $qb->token('aa'),
  $qb->token('bb')
);

is($wrap->to_string, "constr(pos=precedes;precedesDirectly,class=5:[aa],[bb])", 'Query is valid');
ok($query = $wrap->normalize->finalize->identify($index->dict)->optimize($index->segment), 'Planning');
# is($query->to_string, "constr(pos=3,class=5:#2,#4)", 'Query is valid');

matches(
  $query, [
    '[0:0-2]',
    '[0:0-4$0,5,1,2]',
    '[0:0-6$0,5,1,4]',
    '[0:2-4]',
    '[0:2-6$0,5,3,4]',
    '[0:4-6]'
  ]
);

done_testing;
__END__
