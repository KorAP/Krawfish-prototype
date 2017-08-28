use Test::More;
use Test::Krawfish;
use strict;
use warnings;
use Data::Dumper;

use_ok('Krawfish::Index');
use_ok('Krawfish::Koral::Query::Builder');

my $index = Krawfish::Index->new;

ok_index($index, [qw/aa bb bb bb bb cc/], 'Add new document');

my $qb = Krawfish::Koral::Query::Builder->new;

ok(my $wrap = $qb->repeat( $qb->token('bb'), 2, 3), 'Repeat');
is($wrap->to_string, '[bb]{2,3}', 'Stringification');
ok(my $rep = $wrap->normalize->finalize->identify($index->dict)->optimize($index->segment), 'Rewrite');
# is($rep->to_string, "rep(2-3:#4)", 'Stringification');

# This is 4 * 2
is($rep->max_freq, 8, 'Frequency');

# Expect:
# aa [bb bb] bb bb cc
# aa [bb bb bb] bb cc
# aa bb [bb bb] bb cc
# aa bb [bb bb bb] cc
# aa bb bb [bb bb] cc
matches($rep, [qw/[0:1-3]
                  [0:1-4]
                  [0:2-4]
                  [0:2-5]
                  [0:3-5]/]);


# Next test
$index = Krawfish::Index->new;
ok_index($index, [qw/aa bb bb bb cc/], 'Add new document');
ok_index($index, [qw/bb bb bb bb cc/], 'Add new document');

ok($wrap = $qb->repeat( $qb->token('bb'), 1, 3), 'Repeat');
is($wrap->to_string, '[bb]{1,3}', 'Stringification');
ok($rep = $wrap->normalize->finalize->identify($index->dict)->optimize($index->segment), 'Rewrite');
#is($rep->to_string, "rep(1-3:#4)", 'Stringification');

matches($rep, [qw/[0:1-2]
                  [0:1-3]
                  [0:1-4]
                  [0:2-3]
                  [0:2-4]
                  [0:3-4]
                  [1:0-1]
                  [1:0-2]
                  [1:0-3]
                  [1:1-2]
                  [1:1-3]
                  [1:1-4]
                  [1:2-3]
                  [1:2-4]
                  [1:3-4]/]);

# Next test
$index = Krawfish::Index->new;
ok_index($index, [qw/bb bb bb cc bb bb bb bb dd bb/], 'Add new document');

ok($wrap = $qb->repeat( $qb->token('bb'), 1, 3), 'Repeat');
is($wrap->to_string, '[bb]{1,3}', 'Stringification');
ok($rep = $wrap->normalize->finalize->identify($index->dict)->optimize($index->segment), 'Rewrite');
# is($rep->to_string, "rep(1-3:#2)", 'Stringification');

matches($rep, [qw/[0:0-1]
                  [0:0-2]
                  [0:0-3]
                  [0:1-2]
                  [0:1-3]
                  [0:2-3]
                  [0:4-5]
                  [0:4-6]
                  [0:4-7]
                  [0:5-6]
                  [0:5-7]
                  [0:5-8]
                  [0:6-7]
                  [0:6-8]
                  [0:7-8]
                  [0:9-10]/]);


done_testing;
__END__


