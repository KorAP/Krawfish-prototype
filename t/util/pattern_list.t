#!/url/bin/env perl
use strict;
use warnings;
use Test::More;

use_ok('Krawfish::Util::PatternList');

my @list = pattern_list([1],[2,3]);

is_deeply($list[0],[1,2],'List');
is_deeply($list[1],[1,3],'List');


@list = pattern_list([1,5],[2,3],[4],[7,8,9]);

is_deeply($list[0],[1,2,4,7],'List');
is_deeply($list[1],[1,2,4,8],'List');
is_deeply($list[2],[1,2,4,9],'List');
is_deeply($list[3],[1,3,4,7],'List');
is_deeply($list[4],[1,3,4,8],'List');
is_deeply($list[5],[1,3,4,9],'List');
is_deeply($list[6],[5,2,4,7],'List');
is_deeply($list[7],[5,2,4,8],'List');
is_deeply($list[8],[5,2,4,9],'List');
is_deeply($list[9],[5,3,4,7],'List');
is_deeply($list[10],[5,3,4,8],'List');
is_deeply($list[11],[5,3,4,9],'List');
ok(!$list[12], 'No more lists');

done_testing;
__END__
