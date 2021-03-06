use Unicode::Normalize qw/normalize/;
use utf8;
use Test::More;
use Test::Krawfish;
use strict;
use warnings;
use Data::Dumper;

use_ok('Krawfish::Index');
use_ok('Krawfish::Koral::Query::Builder');

my $index = Krawfish::Index->new;

ok_index_file($index, 'doc1.jsonld', 'Add new document');
ok_index_file($index, 'doc2.jsonld', 'Add new document');

ok(my $qb = Krawfish::Koral::Query::Builder->new, 'Create Koral::Builder');

ok(my $term = $qb->term('Hut')->normalize->finalize->identify($index->dict)->optimize($index->segment), 'Term');
ok(!$term->current, 'Not initialized yet');
is($term->max_freq, 2, 'Frequency');

ok($term->next, 'Init search');
is($term->current->to_string, '[0:11-12]', 'Found string');
ok($term->next, 'More tokens');
is($term->current->to_string, '[1:1-2]', 'Found string');
ok(!$term->next, 'No more tokens');

ok($term = $qb->term('opennlp/c!=N')->normalize->finalize, 'Term');
ok($term->has_warning, 'Warnings');

my $ueber = 'über';
my $ueber_kc = normalize('KC', $ueber);
my $ueber_kd = normalize('KD', $ueber);

ok(my $term1 = $qb->term($ueber_kd)->normalize, 'Normalize');
ok(my $term2 = $qb->term($ueber_kc)->normalize, 'Normalize');

is($term1->to_string, $term2->to_string, 'Compare normalization');

ok($term = $term1->finalize->identify($index->dict)->optimize($index->segment), 'Term');
ok(!$term->current, 'Not initialized yet');
is($term->max_freq, 1, 'Frequency');

done_testing;
