use Test::More;
use Test::Krawfish;
use strict;
use warnings;

use_ok('Krawfish::Koral');
use_ok('Krawfish::Index');

my $index = Krawfish::Index->new;

ok_index($index, '<1:aaa>[hey][hey]</1>', 'Add new document');

my $koral = Krawfish::Koral->new;

my $qb = $koral->query_builder;

# [hey]{0,3}
my $rep = $qb->repeat($qb->token('hey'), 0, 3);
is($rep->to_string, '[hey]{0,3}', 'Stringification');
ok(!$rep->is_any, 'Is not any');
ok($rep->is_optional, 'Is optional');
ok(!$rep->is_null, 'Is not null');
ok(!$rep->is_negative, 'Is not negative');
ok(!$rep->is_extended, 'Is not extended');
ok(!$rep->is_extended_right, 'Is not extended to the right');
ok(!$rep->is_extended_left, 'Is not extended to the left');
is($rep->min_span, 0, 'Span length');
is($rep->max_span, 3, 'Span length');

is($rep->to_string, '[hey]{0,3}', 'Normalization');
ok($rep = $rep->normalize, 'Normalization');
is($rep->min_span, 0, 'Span length');
is($rep->max_span, 3, 'Span length');
is($rep->to_string, 'hey{0,3}', 'Normalization');
ok(!$rep->has_error, 'Error set');
ok($rep = $rep->finalize, 'Normalization');
is($rep->min_span, 1, 'Span length');
is($rep->max_span, 3, 'Span length');
ok($rep->has_warning, 'Error set');
is($rep->warning->[0]->[1], 'Optionality of query is ignored', 'Error');
is($rep->to_string, 'hey{1,3}', 'Normalization');
ok($rep = $rep->optimize($index), 'Normalization');
is($rep->to_string, "rep(1-3:'hey')", 'Normalization');


# [hey]{1,3}
$rep = $qb->repeat($qb->token('hey'), 1, 3);
is($rep->to_string, '[hey]{1,3}', 'Stringification');
ok(!$rep->is_any, 'Is not any');
ok(!$rep->is_optional, 'Is not optional');
ok(!$rep->is_null, 'Is not null');
ok(!$rep->is_negative, 'Is not negative');
ok(!$rep->is_extended, 'Is not extended');
ok(!$rep->is_extended_right, 'Is not extended to the right');
ok(!$rep->is_extended_left, 'Is not extended to the left');
ok($rep = $rep->normalize, 'Normalization');
ok(!$rep->has_error, 'Error not set');
is($rep->to_string, 'hey{1,3}', 'Stringification');
ok($rep = $rep->finalize, 'Normalization');
ok(!$rep->has_error, 'Error not set');
is($rep->to_string, 'hey{1,3}', 'Stringification');
is($rep->min_span, 1, 'Span length');
is($rep->max_span, 3, 'Span length');
ok($rep = $rep->optimize($index), 'Normalization');
is($rep->to_string, "rep(1-3:'hey')", 'Normalization');


# [hey]{2,}
$rep = $qb->repeat($qb->token('hey'), 2, undef);
is($rep->to_string, '[hey]{2,}', 'Stringification');
is($rep->min_span, 2, 'Span length');
is($rep->max_span, -1, 'Span length');
ok(!$rep->is_any, 'Is not any');
ok(!$rep->is_optional, 'Is not optional');
ok(!$rep->is_null, 'Is not null');
ok(!$rep->is_negative, 'Is not negative');
ok(!$rep->is_extended, 'Is not extended');
ok(!$rep->is_extended_right, 'Is not extended to the right');
ok(!$rep->is_extended_left, 'Is not extended to the left');
ok($rep = $rep->normalize, 'Normalization');
is($rep->min_span, 2, 'Span length');
is($rep->max_span, 100, 'Span length');
ok(!$rep->has_error, 'Error not set');
ok($rep->has_warning, 'Error not set');
is($rep->to_string, 'hey{2,100}', 'Stringification');
ok($rep = $rep->finalize, 'Normalization');
ok(!$rep->has_error, 'Error not set');
is($rep->to_string, 'hey{2,100}', 'Stringification');
is($rep->min_span, 2, 'Span length');
is($rep->max_span, 100, 'Span length');
ok($rep = $rep->optimize($index), 'Normalization');
is($rep->to_string, "rep(2-100:'hey')", 'Normalization');


# [hey]*
$rep = $qb->repeat($qb->token('hey'), undef, undef);
is($rep->to_string, '[hey]*', 'Stringification');
ok(!$rep->is_any, 'Is not any');
ok($rep->is_optional, 'Is not optional');
ok(!$rep->is_null, 'Is not null');
ok(!$rep->is_negative, 'Is not negative');
ok(!$rep->is_extended, 'Is not extended');
ok(!$rep->is_extended_right, 'Is not extended to the right');
ok(!$rep->is_extended_left, 'Is not extended to the left');
ok($rep = $rep->normalize, 'Normalization');
ok(!$rep->has_error, 'Error not set');
ok($rep->has_warning, 'Error not set');
is($rep->to_string, 'hey{0,100}', 'Stringification');
ok($rep = $rep->finalize, 'Normalization');
ok(!$rep->has_error, 'Error not set');
ok($rep->has_warning, 'Error not set');
is($rep->warning->[0]->[1], 'Maximum value is limited', 'Error');
is($rep->warning->[1]->[1], 'Optionality of query is ignored', 'Error');
is($rep->to_string, 'hey{1,100}', 'Stringification');
ok($rep = $rep->optimize($index), 'Normalization');
is($rep->to_string, "rep(1-100:'hey')", 'Normalization');


# [hey]{0,2}
$rep = $qb->repeat($qb->token('hey'), undef, 2);
is($rep->to_string, '[hey]{,2}', 'Stringification');
ok(!$rep->is_any, 'Is not any');
ok($rep->is_optional, 'Is optional');
ok(!$rep->is_null, 'Is not null');
ok(!$rep->is_negative, 'Is not negative');
ok(!$rep->is_extended, 'Is not extended');
ok(!$rep->is_extended_right, 'Is not extended to the right');
ok(!$rep->is_extended_left, 'Is not extended to the left');
ok($rep = $rep->normalize, 'Normalization');
ok(!$rep->has_error, 'Error not set');
ok(!$rep->has_warning, 'Error not set');
is($rep->to_string, 'hey{0,2}', 'Stringification');
ok($rep = $rep->finalize, 'Normalization');
ok($rep->has_warning, 'Error not set');
ok(!$rep->has_error, 'Error not set');
is($rep->to_string, 'hey{1,2}', 'Stringification');
is($rep->warning->[0]->[1], 'Optionality of query is ignored', 'Error');
ok($rep = $rep->optimize($index), 'Normalization');
is($rep->to_string, "rep(1-2:'hey')", 'Normalization');


# [hey]{3}
$rep = $qb->repeat($qb->token('hey'), 3, 3);
is($rep->to_string, '[hey]{3}', 'Stringification');
ok(!$rep->is_any, 'Is not any');
ok(!$rep->is_optional, 'Is not optional');
ok(!$rep->is_null, 'Is not null');
ok(!$rep->is_negative, 'Is not negative');
ok(!$rep->is_extended, 'Is not extended');
ok(!$rep->is_extended_right, 'Is not extended to the right');
ok(!$rep->is_extended_left, 'Is not extended to the left');

ok($rep = $rep->normalize, 'Normalization');
ok(!$rep->has_error, 'Error not set');
ok(!$rep->has_warning, 'Error not set');
is($rep->to_string, 'hey{3}', 'Stringification');
ok($rep = $rep->finalize, 'Normalization');
ok(!$rep->has_warning, 'Error not set');
ok(!$rep->has_error, 'Error not set');
is($rep->to_string, 'hey{3}', 'Stringification');
ok($rep = $rep->optimize($index), 'Normalization');
is($rep->to_string, "rep(3-3:'hey')", 'Normalization');


# []{2,4}
$rep = $qb->repeat($qb->token, 2, 4);
is($rep->to_string, '[]{2,4}', 'Stringification');
ok($rep->is_any, 'Is any');
ok(!$rep->is_optional, 'Is not optional');
ok(!$rep->is_null, 'Is not null');
ok(!$rep->is_negative, 'Is not negative');
ok($rep->is_extended, 'Is extended');
ok($rep->is_extended_right, 'Is extended to the right');
ok(!$rep->is_extended_left, 'Is not extended to the left');

ok($rep = $rep->normalize, 'Normalization');
ok(!$rep->has_error, 'Error not set');
ok(!$rep->has_warning, 'Error not set');
is($rep->to_string, '[]{2,4}', 'Stringification');
ok(!$rep->finalize, 'Normalization');
ok(!$rep->has_warning, 'Error not set');
ok($rep->has_error, 'Error not set');
is($rep->error->[0]->[1], 'Unable to search for any tokens', 'Error');


# []{,4}
$rep = $qb->repeat($qb->token, 0, 4);
is($rep->to_string, '[]{0,4}', 'Stringification');
ok($rep->is_any, 'Is any');
ok($rep->is_optional, 'Is optional');
ok(!$rep->is_null, 'Is not null');
ok(!$rep->is_negative, 'Is not negative');
ok($rep->is_extended, 'Is extended');
ok($rep->is_extended_right, 'Is extended to the right');
ok(!$rep->is_extended_left, 'Is not extended to the left');
ok($rep = $rep->normalize, 'Normalization');
ok(!$rep->has_error, 'Error not set');
ok(!$rep->has_warning, 'Error not set');
is($rep->to_string, '[]{0,4}', 'Stringification');
ok(!$rep->finalize, 'Normalization');
ok($rep->has_warning, 'Error not set');
is($rep->warning->[0]->[1], 'Optionality of query is ignored', 'Error');
ok($rep->has_error, 'Error not set');
is($rep->error->[0]->[1], 'Unable to search for any tokens', 'Error');


# []{4,}
$rep = $qb->repeat($qb->token, 4, undef);
is($rep->to_string, '[]{4,}', 'Stringification');
ok($rep->is_any, 'Is any');
ok(!$rep->is_optional, 'Is not optional');
ok(!$rep->is_null, 'Is not null');
ok(!$rep->is_negative, 'Is not negative');
ok($rep->is_extended, 'Is extended');
ok($rep->is_extended_right, 'Is extended to the right');
ok(!$rep->is_extended_left, 'Is not extended to the left');

ok($rep = $rep->normalize, 'Normalization');
ok(!$rep->has_error, 'Error not set');
ok($rep->has_warning, 'Warning set');
is($rep->warning->[0]->[1], 'Maximum value is limited', 'Error');
is($rep->to_string, '[]{4,100}', 'Stringification');
ok(!$rep->finalize, 'Normalization');
ok($rep->has_warning, 'Error not set');
ok($rep->has_error, 'Error not set');
is($rep->error->[0]->[1], 'Unable to search for any tokens', 'Error');


# []{8}
$rep = $qb->repeat($qb->token, 8);
is($rep->to_string, '[]{8}', 'Stringification');
ok($rep->is_any, 'Is any');
ok(!$rep->is_optional, 'Is not optional');
ok(!$rep->is_null, 'Is not null');
ok(!$rep->is_negative, 'Is not negative');
ok($rep->is_extended, 'Is extended');
ok($rep->is_extended_right, 'Is extended to the right');
ok(!$rep->is_extended_left, 'Is not extended to the left');

ok($rep = $rep->normalize, 'Normalization');
ok(!$rep->has_error, 'Error not set');
ok(!$rep->has_warning, 'Warning set');
is($rep->to_string, '[]{8}', 'Stringification');
ok(!$rep->finalize, 'Normalization');
ok(!$rep->has_warning, 'Error not set');
ok($rep->has_error, 'Error not set');
is($rep->error->[0]->[1], 'Unable to search for any tokens', 'Error');

# <x>{2,3}
$rep = $qb->repeat($qb->span('aaa'), 2,3);
is($rep->min_span, 0, 'Span length');
is($rep->max_span, -1, 'Span length');
is($rep->to_string, '<aaa>{2,3}', 'Stringification');
ok(!$rep->is_any, 'Is not any');
ok(!$rep->is_optional, 'Is not optional');
ok(!$rep->is_null, 'Is not null');
ok(!$rep->is_negative, 'Is not negative');
ok(!$rep->is_extended, 'Is not extended');
ok(!$rep->is_extended_right, 'Is not extended to the right');
ok(!$rep->is_extended_left, 'Is not extended to the left');
ok($rep = $rep->normalize, 'Normalization');
ok(!$rep->has_error, 'Error not set');
ok(!$rep->has_warning, 'Warning set');
is($rep->to_string, '<aaa>{2,3}', 'Stringification');
ok($rep = $rep->finalize, 'Normalization');
ok(!$rep->has_warning, 'Error not set');
ok(!$rep->has_error, 'Error not set');
ok($rep = $rep->optimize($index), 'Normalization');
is($rep->to_string, "rep(2-3:'<>aaa')", 'Stringification');

# [0]{,3} -> null
$rep = $qb->repeat($qb->nothing, 0, 3);
is($rep->to_string, '[0]{0,3}', 'Stringification');

ok(!$rep->is_any, 'Is not any');
ok($rep->is_optional, 'Is not optional');
ok(!$rep->is_null, 'Is not null');
ok(!$rep->is_nothing, 'Is not null');
ok(!$rep->is_negative, 'Is not negative');
ok(!$rep->is_extended, 'Is not extended');
ok(!$rep->is_extended_right, 'Is not extended to the right');
ok(!$rep->is_extended_left, 'Is not extended to the left');
ok($rep = $rep->normalize, 'Normalization');
is($rep->to_string, '-', 'Stringification');
ok(!$rep->has_error, 'Error not set');
ok(!$rep->has_warning, 'Warning set');
ok($rep->is_null, 'Is null');
ok(!$rep->is_optional, 'Is not optional');
ok(!$rep->is_nothing, 'Is not null');
ok(!$rep->is_negative, 'Is not negative');
ok(!$rep->is_extended, 'Is not extended');
ok(!$rep->is_extended_right, 'Is not extended to the right');
ok(!$rep->is_extended_left, 'Is not extended to the left');


# [!hey]{0,3}
$rep = $qb->repeat($qb->token('hey')->is_negative(1), 0, 3);
is($rep->to_string, '[!hey]{0,3}', 'Stringification');
ok(!$rep->is_any, 'Is not any');
ok($rep->is_optional, 'Is optional');
ok(!$rep->is_null, 'Is not null');
ok($rep->is_negative, 'Is negative');
ok(!$rep->is_extended, 'Is not extended');
ok(!$rep->is_extended_right, 'Is not extended to the right');
ok(!$rep->is_extended_left, 'Is not extended to the left');


# [hey]{1,1}
$rep = $qb->repeat($qb->token('hey'), 1, 1);
is($rep->to_string, '[hey]{1}', 'Stringification');
ok(!$rep->is_any, 'Is not any');
ok(!$rep->is_optional, 'Is not optional');
ok(!$rep->is_null, 'Is not null');
ok(!$rep->is_negative, 'Is not negative');
ok(!$rep->is_extended, 'Is not extended');
ok(!$rep->is_extended_right, 'Is not extended to the right');
ok(!$rep->is_extended_left, 'Is not extended to the left');
ok($rep = $rep->normalize, 'Normalization');
ok(!$rep->has_error, 'Error not set');
is($rep->to_string, 'hey', 'Stringification');
ok($rep = $rep->finalize, 'Normalization');
ok(!$rep->has_error, 'Error not set');
is($rep->to_string, 'hey', 'Stringification');
ok($rep = $rep->optimize($index), 'Normalization');
is($rep->to_string, "'hey'", 'Normalization');

# [hey]{0,1}
$rep = $qb->repeat($qb->token('hey'), 0, 1);
is($rep->to_string, '[hey]?', 'Stringification');
ok(!$rep->is_any, 'Is not any');
ok($rep->is_optional, 'Is optional');
ok(!$rep->is_null, 'Is not null');
ok(!$rep->is_negative, 'Is not negative');
ok(!$rep->is_extended, 'Is not extended');
ok(!$rep->is_extended_right, 'Is not extended to the right');
ok(!$rep->is_extended_left, 'Is not extended to the left');
is($rep->to_string, '[hey]?', 'Normalization');
ok($rep = $rep->normalize, 'Normalization');
is($rep->to_string, 'hey?', 'Normalization');
ok(!$rep->has_error, 'Error set');
ok($rep = $rep->finalize, 'Normalization');
ok($rep->has_warning, 'Error set');
is($rep->warning->[0]->[1], 'Optionality of query is ignored', 'Error');
is($rep->to_string, 'hey', 'Normalization');
ok($rep = $rep->optimize($index), 'Normalization');
is($rep->to_string, "'hey'", 'Normalization');


# Flip classes
# {4:[hey]}{0,1}
$rep = $qb->repeat($qb->class($qb->token('hey'), 4), 0, 1);
is($rep->to_string, '{4:[hey]}?', 'Stringification');
is($rep->min_span, 0, 'Span length');
is($rep->max_span, 1, 'Span length');
ok($rep = $rep->normalize, 'Normalization');
is($rep->to_string, '{4:hey?}', 'Stringification');
is($rep->min_span, 0, 'Span length');
is($rep->max_span, 1, 'Span length');


# {4:{5:[hey]}}{4,5}
$rep = $qb->repeat($qb->class($qb->class($qb->token('hey'), 5), 4), 4, 5);
is($rep->min_span, 4, 'Span length');
is($rep->max_span, 5, 'Span length');
is($rep->to_string, '{4:{5:[hey]}}{4,5}', 'Stringification');
ok($rep = $rep->normalize, 'Normalization');
is($rep->to_string, '{4:{5:hey{4,5}}}', 'Stringification');
is($rep->min_span, 4, 'Span length');
is($rep->max_span, 5, 'Span length');


# ([a][b]){4,5}
$rep = $qb->repeat($qb->seq($qb->token('a'), $qb->token('b')), 4, 5);
is($rep->to_string, '([a][b]){4,5}', 'Stringification');
is($rep->min_span, 8, 'Span length');
is($rep->max_span, 10, 'Span length');
ok($rep = $rep->normalize, 'Normalization');
is($rep->to_string, '(ab){4,5}', 'Stringification');
is($rep->min_span, 8, 'Span length');
is($rep->max_span, 10, 'Span length');


# ([a][b]?){4,5}
$rep = $qb->repeat($qb->seq($qb->token('a'), $qb->repeat($qb->token('b'),0,1)), 4, 5);
is($rep->to_string, '([a][b]?){4,5}', 'Stringification');
is($rep->min_span, 4, 'Span length');
is($rep->max_span, 10, 'Span length');
ok($rep = $rep->normalize, 'Normalization');
is($rep->to_string, '(ab?){4,5}', 'Stringification');
is($rep->min_span, 4, 'Span length');
is($rep->max_span, 10, 'Span length');


done_testing;
__END__
