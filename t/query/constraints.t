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
ok(my $query = $wrap->plan_for($index), 'Planning');
is($query->to_string, "constr(pos=2:'aa','bb')", 'Query is valid');

matches($query, [qw/[0:0-2] [0:0-2] [0:0-2] [0:0-2]/]);


done_testing;

__END__
