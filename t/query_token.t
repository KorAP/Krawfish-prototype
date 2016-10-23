use Test::More;
use strict;
use warnings;
use Data::Dumper;

use_ok('Krawfish::Index');
use_ok('Krawfish::QueryBuilder');

my $index = Krawfish::Index->new('index.dat');

ok($index->add('t/data/doc1.jsonld'), 'Add new document');
ok($index->add('t/data/doc2.jsonld'), 'Add new document');

ok(my $qb = Krawfish::QueryBuilder->new($index), 'Create QueryBuilder');

ok(my $term = $qb->token('Hut'), 'Term');
ok(!$term->current, 'Not initialized yet');

is($term->freq, 2, 'Frequency');

ok($term->next, 'Init search');
is($term->current->to_string, '[0:11-12]', 'Found string');
ok($term->next, 'More tokens');
is($term->current->to_string, '[1:1-2]', 'Found string');
ok(!$term->next, 'No more tokens');

done_testing;
