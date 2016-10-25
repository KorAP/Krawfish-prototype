use Test::More;
use strict;
use warnings;
use Data::Dumper;

use_ok('Krawfish::Index');
use_ok('Krawfish::QueryBuilder');

my $index = Krawfish::Index->new('index.dat');

ok($index->add('t/data/doc3-segments.jsonld'), 'Add new document');

ok(my $qb = Krawfish::QueryBuilder->new($index), 'Create QueryBuilder');

ok(my $span = $qb->span('akron/c=NP'), 'Span');
ok(!$span->current, 'Not initialized yet');

is($span->freq, 2, 'Frequency');

ok($span->next, 'Init search');
is($span->current->to_string, '[0:0-2]', 'Found string');
ok($span->next, 'More tokens');
is($span->current->to_string, '[0:4-7]', 'Found string');
ok(!$span->next, 'No more tokens');


done_testing;

__END__



