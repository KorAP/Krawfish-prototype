use Test::More;
use strict;
use warnings;
use Data::Dumper;

use_ok('Krawfish::Koral');
use_ok('Krawfish::Index');

my $index = Krawfish::Index->new;

ok(defined $index->add('t/data/doc3-segments.jsonld'), 'Add new document');

my $koral = Krawfish::Koral->new;

my $builder = $koral->query_builder;

# Span planning
my $query = $builder->span('akron/c=NP');
ok(!$query->is_any, 'Is any');
ok(!$query->is_optional, 'Isn\'t optional');
ok(!$query->is_null, 'Isn\'t null');
ok(!$query->is_negative, 'Isn\'t negative');
ok(!$query->is_extended, 'Isn\'t extended');
is($query->to_string, '<akron/c=NP>', 'Stringification');
is($query->plan_for($index)->to_string, "'<>akron/c=NP'", 'Planned Stringification');


# Span planning with zero freq
$query = $builder->span('xxxx');
is($query->to_string, '<xxxx>', 'Stringification');
is($query->plan_for($index)->to_string, "[0]", 'Planned Stringification');

done_testing;
