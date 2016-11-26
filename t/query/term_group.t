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
  $qb->term_and('aa', $qb->term_neg('bb'))
);
is($token->to_string, '[aa&!bb]', 'Stringification');
ok(my $plan = $token->plan_for($index), 'Planning');
is($plan->to_string, "excl(32:'aa','bb')", 'Stringification');

matches($plan, ['[0:2-3]']);

# [aa&!bb]
$index = Krawfish::Index->new;
ok_index($index, '[aa|bb][aa|bb|cc][aa][bb|cc]', 'Add complex document');
$token = $qb->token(
  $qb->term_or(
    $qb->term_and('aa', $qb->term_neg('bb')),
    $qb->term_and('bb', 'cc')
  )
);
is($token->to_string, '[(aa&!bb)|(bb&cc)]', 'Stringification');
ok($plan = $token->plan_for($index), 'Planning');
is($plan->to_string, "or(excl(32:'aa','bb'),pos(32:'bb','cc'))", 'Stringification');
matches($plan, ['[0:1-2]', '[0:2-3]','[0:3-4]']);



done_testing;
__END__

