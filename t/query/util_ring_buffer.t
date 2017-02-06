#!/url/bin/env perl
use strict;
use warnings;
use Test::More;

use_ok('Krawfish::Query::Util::RingBuffer');

ok(my $buff = Krawfish::Query::Util::RingBuffer->new(20), 'New ring buffer');

done_testing;
__END__
