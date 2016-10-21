use Test::More;
use strict;
use warnings;
use constant {
  NEXTA => 1,
    NEXTB => 2,
    STOREB => 4,
    MATCH => 8
  };

is(NEXTA | NEXTB, 3, 'nexta and nextb flag set');
is(NEXTB | STOREB, 6, 'nextb and storeb flag set');

my $match_nextb = MATCH | NEXTB;
ok($match_nextb & MATCH, 'Match is set');
ok($match_nextb & NEXTB, 'NextB is set');
ok(!($match_nextb & NEXTA), 'NextA is not set');
ok(!($match_nextb & STOREB), 'STOREB is not set');

done_testing;
