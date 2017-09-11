use Test::More;
use Test::Krawfish;
use strict;
use warnings;
use Data::Dumper;

use_ok('Krawfish::Koral');
use_ok('Krawfish::Index');

my $index = Krawfish::Index->new;

ok_index_file($index, 'doc3-segments.jsonld', 'Add new document');

my $koral = Krawfish::Koral->new;

my $builder = $koral->query_builder;

# Span planning
my $query = $builder->span('akron/c=NP');
ok(!$query->is_anywhere, 'Is anywhere');
ok(!$query->is_optional, 'Isn\'t optional');
ok(!$query->is_null, 'Isn\'t null');
ok(!$query->is_negative, 'Isn\'t negative');
ok(!$query->is_extended, 'Isn\'t extended');
is($query->to_string, '<akron/c=NP>', 'Stringification');

ok($query = $query->normalize, 'Normalization');
is($query->to_string, "<akron/c=NP>", 'Stringification');
ok($query = $query->identify($index->dict)->optimize($index->segment), 'Normalization');
is($query->to_string, "#11", 'Stringification');

# Span planning with zero freq
$query = $builder->span('xxxx');
is($query->to_string, '<xxxx>', 'Stringification');
ok($query = $query->normalize, 'Normalization');
is($query->to_string, "<xxxx>", 'Stringification');
ok($query = $query->identify($index->dict)->optimize($index->segment), 'Normalization');
is($query->to_string, "[0]", 'Stringification');

done_testing;
__END__
