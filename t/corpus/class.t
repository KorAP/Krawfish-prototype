use Test::More;
use Test::Krawfish;
use strict;
use warnings;

use_ok('Krawfish::Corpus::Class');
use_ok('Krawfish::Util::Bits', 'bitstring');

ok(my $class = Krawfish::Corpus::Class->new(undef, 4), 'Create class corpus');
is($class->flag, '0001000000000000', 'Get flag');

diag 'Test corpus class behaviour';

done_testing;
