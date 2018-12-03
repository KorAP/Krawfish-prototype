#!/url/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Krawfish::RepetitionPattern;

use_ok('Krawfish::Util::RepetitionPattern');

my $repp;
$repp = Krawfish::Util::RepetitionPattern->new([2]);
ok_repetition($repp, [2], 'First test');


$repp = Krawfish::Util::RepetitionPattern->new([0,2]);
ok_repetition($repp, [0,1,2], 'First test');


$repp = Krawfish::Util::RepetitionPattern->new([2],[1,3]);
ok_repetition($repp, [2,4,6], 'First test');


$repp = Krawfish::Util::RepetitionPattern->new([0,1], [2],[1,3]);
ok_repetition($repp, [0,2,4,6], 'First test');

$repp = Krawfish::Util::RepetitionPattern->new([0,2], [2], [1,3]);
ok_repetition($repp, [0,2,4,6,8,12], 'First test');


done_testing;
__END__
