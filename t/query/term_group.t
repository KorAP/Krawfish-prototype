use Test::More;
use Test::Krawfish;
use strict;
use warnings;

use_ok('Krawfish::Koral::Query::Builder');
use_ok('Krawfish::Index');

my $qb = Krawfish::Koral::Query::Builder->new;

# [aa&!bb]
my $index = Krawfish::Index->new;
ok_index($index, '[aa|bb][aa|bb|cc][aa][bb|cc]', 'Add complex document');
my $token = $qb->token(
  $qb->bool_and('aa', $qb->term_neg('bb'))
);
is($token->to_string, '[!bb&aa]', 'Stringification');
ok($token = $token->normalize, 'Normalization');
is($token->to_string, 'excl(matches:aa,bb)', 'Stringification');
ok(my $plan = $token->identify($index->dict)->optimize($index->segment), 'Optimalization');


matches($plan, ['[0:2-3]']);

# [aa&!bb]
$index = Krawfish::Index->new;
ok_index($index, '[aa|bb][aa|bb|cc][aa][bb|cc]', 'Add complex document');
$token = $qb->token(
  $qb->bool_or(
    $qb->bool_and('aa', $qb->term_neg('bb')),
    $qb->bool_and('bb', 'cc')
  )
);
is($token->to_string, '[(!bb&aa)|(bb&cc)]', 'Stringification');
ok($token = $token->normalize, 'Normalization');
is($token->to_string, '(bb&cc)|excl(matches:aa,bb)', 'Stringification');
ok($plan = $token->identify($index->dict)->optimize($index->segment), 'Planning');
# is($plan->to_string, "or(constr(pos=32:#3,#4),excl(32:#2,#3))", 'Stringification');
matches($plan, ['[0:1-2]', '[0:2-3]','[0:3-4]']);

done_testing;
__END__

