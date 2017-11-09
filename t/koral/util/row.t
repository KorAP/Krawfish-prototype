#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use_ok('Krawfish::Koral::Util::Row');

ok(my $row = Krawfish::Koral::Util::Row->from_columns(qw/peter michael hermann/), 'Row');

is($row->columns->[0], 'peter', 'First column');
is($row->columns->[1], 'michael', 'Second column');
is($row->columns->[2], 'hermann', 'Third column');

is(my $sig = $row->signature, 'J3BldGVyJzsnbWljaGFlbCc7J2hlcm1hbm4n', 'Get signature');

ok($row = Krawfish::Koral::Util::Row->from_signature($sig), 'Row');

is($row->columns->[0], 'peter', 'First column');
is($row->columns->[1], 'michael', 'Second column');
is($row->columns->[2], 'hermann', 'Third column');


done_testing;
__END__
