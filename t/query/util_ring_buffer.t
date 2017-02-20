#!/url/bin/env perl
use strict;
use warnings;
use Test::More;

use_ok('Krawfish::Util::RingBuffer');

ok(my $buff = Krawfish::Util::RingBuffer->new(20), 'New ring buffer');

done_testing;
__END__
