use Test::More;
use strict;
use warnings;
use Data::Dumper;

use_ok('Krawfish::Koral');

my $koral = Krawfish::Koral->new;

my $builder = $koral->query_builder;

my $query = $builder->term('Der');
ok(!$query->is_anywhere, 'Isn\'t anywhere');
ok(!$query->is_optional, 'Isn\'t optional');
ok(!$query->is_null, 'Isn\'t null');
ok(!$query->is_negative, 'Isn\'t negative');
ok(!$query->is_extended, 'Isn\'t extended');
is($query->to_string, 'Der', 'Stringification');
is($query->min_span, 1, 'Span length');
is($query->max_span, 1, 'Span length');

$query = $builder->term('opennlp/c!=NN');
ok(!$query->is_anywhere, 'Isn\'t anywhere');
ok(!$query->is_optional, 'Isn\'t optional');
ok(!$query->is_null, 'Isn\'t null');
ok($query->is_negative, 'Isn\'t negative');
ok(!$query->is_extended, 'Isn\'t extended');
is($query->to_string, 'opennlp/c!=NN', 'Stringification');
is($query->min_span, 1, 'Span length');
is($query->max_span, 1, 'Span length');


$query = $builder->null;
ok(!$query->is_anywhere, 'Is not anywhere');
ok(!$query->is_optional, 'Isn\'t optional');
ok($query->is_null, 'Isn\'t null');
ok(!$query->is_negative, 'Isn\'t negative');
ok(!$query->is_extended, 'Isn\'t extended');
is($query->to_string, '-', 'Stringification');
ok(!$query->normalize->finalize, 'Planned Stringification');
is($query->min_span, 0, 'Span length');
is($query->max_span, 0, 'Span length');

done_testing;

__END__
