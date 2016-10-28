use Test::More;
use strict;
use warnings;

use constant {
  NULL   => 0b0000_0000,
  NEXTA  => 0b0000_0001,
  NEXTB  => 0b0000_0010,
  STOREB => 0b0000_0100,
  MATCH  => 0b0000_1000
};

sub dec2bin8 {
  return unpack "B8", pack "C", shift;
}

is(NEXTA | NEXTB,  0b00000011, 'nexta and nextb flag set');
is(NEXTB | STOREB, 0b00000110, 'nextb and storeb flag set');

my $match_nextb = MATCH | NEXTB;
ok($match_nextb & MATCH, 'Match is set');
ok($match_nextb & NEXTB, 'NextB is set');
ok(!($match_nextb & NEXTA), 'NextA is not set');
ok(!($match_nextb & STOREB), 'STOREB is not set');

done_testing;
