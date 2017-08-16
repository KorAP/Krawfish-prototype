use Test::More;
use Test::Krawfish;
use strict;
use warnings;
use Data::Dumper;

use_ok('Krawfish::Koral');
use_ok('Krawfish::Index');

my $index = Krawfish::Index->new;

ok_index_file($index, 'doc1.jsonld', 'Add new document');

my $koral = Krawfish::Koral->new;
my $qb = $koral->query_builder;

my $query = $qb->class($qb->token('Der'), 3);
is($query->min_span, 1, 'Span length');
is($query->max_span, 1, 'Span length');
is($query->to_string, '{3:[Der]}', 'Stringification');
ok($query = $query->normalize, 'Normalize');
is($query->to_string, "{3:Der}", 'Planned Stringification');
ok($query = $query->identify($index->dict)->optimize($index->segment), 'Optimize');
# is($query->to_string, "class(3:#10)", 'Planned Stringification');

$query = $qb->class($qb->token('der'), 3);
is($query->min_span, 1, 'Span length');
is($query->max_span, 1, 'Span length');
is($query->to_string, '{3:[der]}', 'Stringification');
ok($query = $query->normalize, 'Normalize');
is($query->to_string, '{3:der}', 'Stringification');
ok($query = $query->identify($index->dict)->optimize($index->segment), 'Optimize');
is($query->to_string, "[0]", 'Planned Stringification');

$query = $qb->class($qb->token('der')->is_negative(1), 3);
is($query->min_span, 1, 'Span length');
is($query->max_span, 1, 'Span length');
is($query->to_string, '{3:[!der]}', 'Stringification');
ok($query = $query->normalize, 'Normalize');
is($query->to_string, '[!der]', 'Stringification');

done_testing;
__END__

