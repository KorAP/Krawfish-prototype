#!/url/bin/env perl
use strict;
use warnings;
use Test::More;

use_ok('Krawfish::Query::Util::Buffer');
use_ok('Krawfish::Posting::Token');

ok(my $buff = Krawfish::Query::Util::Buffer->new, 'New candidates');

ok(!$buff->current, 'No current');
is($buff->size, 0, 'Size 0');
is($buff->finger, 0, 'Finger 0');
ok(!$buff->next, 'No next');
is($buff->size, 0, 'Size 0');
is($buff->finger, 1, 'Finger 1');

ok($buff->remember(Krawfish::Posting::Token->new(0,2,3)), 'Remember');
is($buff->size, 1, 'Size 0');
is($buff->finger, 1, 'Size 0');
ok(!$buff->current, 'Current');
is($buff->to_string, '[0:2-3] <> ', 'Current');

ok(!$buff->next, 'Nothing next');
is($buff->to_string, '[0:2-3] <> ', 'Current');

ok(!$buff->current, 'No current');
is($buff->size, 1, 'Size 0');
is($buff->finger, 2, 'Finger 2');

$buff->rewind;
is($buff->size, 1, 'Size 0');
is($buff->finger, 0, 'Size 0');
is($buff->current, '[0:2-3]', 'Current');

ok($buff->remember(Krawfish::Posting::Token->new(0,5,6)), 'Remember');
is($buff->size, 2, 'Size 2');
is($buff->finger, 0, 'Size 1');
is($buff->current, '[0:2-3]', 'Current');

ok($buff->next, 'Next is fine');
is($buff->finger, 1, 'Size 0');
is($buff->current, '[0:5-6]', 'Current');

is($buff->to_string, '[0:2-3] <[0:5-6]> ', 'Buffer string');

ok(!$buff->next, 'Next is fine');
is($buff->finger, 2, 'Finger 2');
ok(!$buff->current, 'Current');

ok($buff->forget, 'Forget first element');
is($buff->size, 1, 'Size 1');
is($buff->finger, 1, 'Finger 1');

is($buff->to_string, '[0:5-6] <> ', 'Stringify');
ok($buff->remember(Krawfish::Posting::Token->new(0,8,9)), 'Remember');
is($buff->to_string, '[0:5-6] <[0:8-9]> ', 'Stringify');
$buff->rewind;
is($buff->to_string, ' <[0:5-6]> [0:8-9]', 'Stringify');
$buff->to_end;
is($buff->to_string, '[0:5-6] <[0:8-9]> ', 'Stringify');

$buff->clear;
is($buff->size, 0, 'Size 0');
is($buff->finger, 0, 'Finger 0');
ok(!$buff->current, 'Current');

done_testing;

1;

__END__

