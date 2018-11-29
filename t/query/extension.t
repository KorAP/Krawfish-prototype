use Test::More;
use Test::Krawfish;
use strict;
use warnings;
use Data::Dumper;

use_ok('Krawfish::Index');
use_ok('Krawfish::Koral::Query::Builder');

my $index = Krawfish::Index->new;

ok_index($index, [qw/bb bb cc dd dd/], 'Add new document');

my $qb = Krawfish::Koral::Query::Builder->new;

# Right expansion

# [bb][]{1,3}
# extend(1-3, 'right', bb)
# [bb][bb][cc][dd][dd]
# 1. bb bb
# 2. bb bb cc
# 3. bb bb cc dd
# 4.    bb cc
# 5.    bb cc dd
# 6.    bb cc dd dd
ok(my $wrap = $qb->seq($qb->token('bb'), $qb->repeat($qb->token, 1, 3)),
   'Extension to the right');
is($wrap->to_string, '[bb][]{1,3}', 'Stringification');

ok(my $ext = $wrap->normalize->finalize->identify($index->dict)->optimize($index->segment), 'Rewrite');
is($ext->to_string, 'ext(>:1-3,#2)', 'Stringification');
is($ext->max_freq, 6);
#matches($ext, [qw/[0:1-2]/]);


# Left expansion

# []{0,3} [bb]
# extend(0-3, 'left', dd)
# [bb][bb][cc][dd][dd]
# 1. bb bb cc dd
# 2.    bb cc dd
# 3.    bb cc dd dd
# 4.       cc dd
# 5.       cc dd dd
# 6.          dd
# 7.          dd dd
# 8.             dd
ok($wrap = $qb->seq($qb->repeat($qb->token, 0, 3), $qb->token('dd')), 'Extension to the left');
is($wrap->to_string, '[]{0,3}[dd]', 'Stringification');

ok($ext = $wrap->normalize->finalize->identify($index->dict)->optimize($index->segment), 'Rewrite');
is($ext->to_string, 'ext(<:0-3,#6)', 'Stringification');
is($ext->max_freq, 8);


# Normalize extensions:
ok($wrap = $qb->seq($qb->token('bb'), $qb->repeat($qb->token, 0, 2), $qb->repeat($qb->token, 1, 3)),
   'Extension to the right');
is($wrap->to_string, '[bb][]{0,2}[]{1,3}', 'Stringification');

ok($ext = $wrap->normalize->finalize->identify($index->dict)->optimize($index->segment), 'Rewrite');
is($ext->to_string, 'ext(>:1-5,#2)', 'Stringification');



done_testing;
__END__
