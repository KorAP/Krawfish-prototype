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

ok(my $term = $qb->term('Hut'), 'Term');
is($term->to_string, 'Hut');
ok($term = $term->normalize, 'Term');
is($term->to_string, 'Hut');

ok($term = $term->identify($index->dict), 'To term ids');

# Probably don't check that!
# is($term->to_string, '#32', 'Hut-term_id');

ok($term = $term->optimize($index->segment), 'Optimize');

# Probably don't check that!
# is($term->to_string, '#32', 'Hut-term_id');


ok(!$term->current, 'Not initialized yet');
is($term->max_freq, 2, 'Frequency');

ok($term->next, 'Init search');
is($term->current->to_string, '[0:11-12]', 'Found string');
ok($term->next, 'More tokens');
is($term->current->to_string, '[1:1-2]', 'Found string');
ok(!$term->next, 'No more tokens');

ok($term = $qb->term('opennlp/c!=N')->normalize->finalize, 'Term');
ok($term->has_warning, 'Warnings');


done_testing;

__END__

