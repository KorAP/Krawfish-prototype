use strict;
use warnings;
use Test::Krawfish;
use Test::More;

use_ok('Krawfish::Index');
use_ok('Krawfish::Koral::Query::Builder');

my $index = Krawfish::Index->new;
ok_index($index, [qw/aa bb aa bb aa bb aa bb aa bb/], 'Add complex document');

my $qb = Krawfish::Koral::Query::Builder->new;

my $wrap = $qb->length(
  $qb->constraints(
    [$qb->c_position('precedes')],
    $qb->token('aa'),
    $qb->token('bb')
  ),
  3,
  5
);

is($wrap->to_string, "length(3-5:constr(pos=precedes:[aa],[bb]))", 'Query is valid');
ok(my $query = $wrap->normalize->finalize->optimize($index), 'Planning');
is($query->to_string, "length(3-5:constr(pos=1:'aa','bb'))", 'Query is valid');

matches($query, [qw/[0:0-4] [0:2-6] [0:4-8] [0:6-10]/]);


done_testing;
__END__
