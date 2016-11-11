use Test::More;
use strict;
use warnings;
use Data::Dumper;

use_ok('Krawfish::Koral');
use_ok('Krawfish::Index');

my $index = Krawfish::Index->new;

ok(defined $index->add('t/data/doc1.jsonld'), 'Add new document');

my $koral = Krawfish::Koral->new;

my $builder = $koral->query_builder;

# [hey]{0,3}
my $rep = $builder->repeat($builder->token('hey'), 0, 3);
is($rep->to_string, '[hey]{0,3}', 'Stringification');
ok(!$rep->is_any, 'Is not any');
ok($rep->is_optional, 'Is optional');
ok(!$rep->is_null, 'Is not null');
ok(!$rep->is_negative, 'Is not negative');
ok(!$rep->is_extended, 'Is not extended');
ok(!$rep->is_extended_right, 'Is not extended to the right');
ok(!$rep->is_extended_left, 'Is not extended to the left');

# [hey]{1,3}
$rep = $builder->repeat($builder->token('hey'), 1, 3);
is($rep->to_string, '[hey]{1,3}', 'Stringification');
ok(!$rep->is_any, 'Is not any');
ok(!$rep->is_optional, 'Is not optional');
ok(!$rep->is_null, 'Is not null');
ok(!$rep->is_negative, 'Is not negative');
ok(!$rep->is_extended, 'Is not extended');
ok(!$rep->is_extended_right, 'Is not extended to the right');
ok(!$rep->is_extended_left, 'Is not extended to the left');

# [hey]{2,}
$rep = $builder->repeat($builder->token('hey'), 2, undef);
is($rep->to_string, '[hey]{2,}', 'Stringification');
ok(!$rep->is_any, 'Is not any');
ok(!$rep->is_optional, 'Is not optional');
ok(!$rep->is_null, 'Is not null');
ok(!$rep->is_negative, 'Is not negative');
ok(!$rep->is_extended, 'Is not extended');
ok(!$rep->is_extended_right, 'Is not extended to the right');
ok(!$rep->is_extended_left, 'Is not extended to the left');

# [hey]{0,2}
$rep = $builder->repeat($builder->token('hey'), undef, 2);
is($rep->to_string, '[hey]{0,2}', 'Stringification');
ok(!$rep->is_any, 'Is not any');
ok($rep->is_optional, 'Is optional');
ok(!$rep->is_null, 'Is not null');
ok(!$rep->is_negative, 'Is not negative');
ok(!$rep->is_extended, 'Is not extended');
ok(!$rep->is_extended_right, 'Is not extended to the right');
ok(!$rep->is_extended_left, 'Is not extended to the left');

# [hey]{3}
$rep = $builder->repeat($builder->token('hey'), 3, 3);
is($rep->to_string, '[hey]{3}', 'Stringification');
ok(!$rep->is_any, 'Is not any');
ok(!$rep->is_optional, 'Is not optional');
ok(!$rep->is_null, 'Is not null');
ok(!$rep->is_negative, 'Is not negative');
ok(!$rep->is_extended, 'Is not extended');
ok(!$rep->is_extended_right, 'Is not extended to the right');
ok(!$rep->is_extended_left, 'Is not extended to the left');

# []{2,4}
$rep = $builder->repeat($builder->token, 2, 4);
is($rep->to_string, '[]{2,4}', 'Stringification');
ok($rep->is_any, 'Is any');
ok(!$rep->is_optional, 'Is not optional');
ok(!$rep->is_null, 'Is not null');
ok(!$rep->is_negative, 'Is not negative');
ok($rep->is_extended, 'Is extended');
ok($rep->is_extended_right, 'Is extended to the right');
ok(!$rep->is_extended_left, 'Is not extended to the left');

# []{,4}
$rep = $builder->repeat($builder->token, 0, 4);
is($rep->to_string, '[]{0,4}', 'Stringification');
ok($rep->is_any, 'Is any');
ok($rep->is_optional, 'Is optional');
ok(!$rep->is_null, 'Is not null');
ok(!$rep->is_negative, 'Is not negative');
ok($rep->is_extended, 'Is extended');
ok($rep->is_extended_right, 'Is extended to the right');
ok(!$rep->is_extended_left, 'Is not extended to the left');

# []{4,}
$rep = $builder->repeat($builder->token, 4, undef);
is($rep->to_string, '[]{4,}', 'Stringification');
ok($rep->is_any, 'Is any');
ok(!$rep->is_optional, 'Is not optional');
ok(!$rep->is_null, 'Is not null');
ok(!$rep->is_negative, 'Is not negative');
ok($rep->is_extended, 'Is extended');
ok($rep->is_extended_right, 'Is extended to the right');
ok(!$rep->is_extended_left, 'Is not extended to the left');

# []{8}
$rep = $builder->repeat($builder->token, 8);
is($rep->to_string, '[]{8}', 'Stringification');
ok($rep->is_any, 'Is any');
ok(!$rep->is_optional, 'Is not optional');
ok(!$rep->is_null, 'Is not null');
ok(!$rep->is_negative, 'Is not negative');
ok($rep->is_extended, 'Is extended');
ok($rep->is_extended_right, 'Is extended to the right');
ok(!$rep->is_extended_left, 'Is not extended to the left');

# <x>{2,3}
$rep = $builder->repeat($builder->span('aaa'), 2,3);
is($rep->to_string, '<aaa>{2,3}', 'Stringification');
ok(!$rep->is_any, 'Is not any');
ok(!$rep->is_optional, 'Is not optional');
ok(!$rep->is_null, 'Is not null');
ok(!$rep->is_negative, 'Is not negative');
ok(!$rep->is_extended, 'Is not extended');
ok(!$rep->is_extended_right, 'Is not extended to the right');
ok(!$rep->is_extended_left, 'Is not extended to the left');


done_testing;

__END__



