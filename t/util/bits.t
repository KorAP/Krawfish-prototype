#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use_ok('Krawfish::Util::Bits');

is(bitstring(0b0001_0001_0000_0001), '1000000010001000', 'Bitstring');
is(bitstring(0b1001_0001_0000_0000), '0000000010001001', 'Bitstring');

is(classes_to_flags(2,3), 0b0011_0000_0000_0000, 'classes to flags');
is(classes_to_flags(2,3,6), 0b0011_0010_0000_0000, 'classes to flags');


is_deeply([flags_to_classes(0b0011_0000_0000_0000)], [2,3], 'flags to classes');
is_deeply([flags_to_classes(0b0011_0010_0000_0000)], [2,3,6], 'flags to classes');


is(bitstring(32768), '0000000000000001', 'Bitstring');
is_deeply([flags_to_classes(32768)], [0], 'flags to classes');

done_testing;
__END__
