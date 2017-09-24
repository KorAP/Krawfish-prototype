use Test::More;
use Krawfish::Util::Constants qw/:PREFIX/;
use strict;
use warnings;
use Data::Dumper;

use_ok('Krawfish::Koral::Query::Term');

my $term = Krawfish::Koral::Query::Term->new('baum');
ok(!$term->field,   'No field');
ok(!$term->prefix,  'No prefix');
ok(!$term->foundry, 'No foundry');
ok(!$term->layer,   'No layer');
is($term->key, 'baum', 'Key');
ok(!$term->value,   'No value');

$term = Krawfish::Koral::Query::Term->new(SPAN_PREF . 'baum');
ok(!$term->field,   'No field');
is($term->prefix, SPAN_PREF, 'Prefix');
ok(!$term->foundry, 'No foundry');
ok(!$term->layer,   'No layer');
is($term->key, 'baum', 'Key');
ok(!$term->value,   'No value');

$term = Krawfish::Koral::Query::Term->new('opennlp=baum');
ok(!$term->field,   'No field');
ok(!$term->prefix,  'No prefix');
is($term->foundry, 'opennlp', 'Foundry');
ok(!$term->layer,   'No layer');
is($term->key, 'baum', 'Key');
ok(!$term->value,   'No value');

$term = Krawfish::Koral::Query::Term->new('opennlp/c=baum');
ok(!$term->field,   'No field');
ok(!$term->prefix,  'No prefix');
is($term->foundry, 'opennlp', 'Foundry');
is($term->layer, 'c', 'Layer');
is($term->key, 'baum', 'Key');
ok(!$term->value,   'No value');

$term = Krawfish::Koral::Query::Term->new('opennlp/p=gender:m');
ok(!$term->field, 'No field');
ok(!$term->prefix, 'No prefix');
is($term->foundry, 'opennlp', 'Foundry');
is($term->layer, 'p', 'Layer');
is($term->key, 'gender', 'Key');
is($term->value, 'm', 'Value');

$term = Krawfish::Koral::Query::Term->new('opennlp/p != gender:m');
ok(!$term->field, 'No field');
ok(!$term->prefix, 'No prefix');
is($term->foundry, 'opennlp', 'Foundry');
is($term->match, '!=', 'Layer');
is($term->layer, 'p', 'Layer');
is($term->key, 'gender', 'Key');
is($term->value, 'm', 'Value');
is($term->to_string, 'opennlp/p!=gender:m', 'Term');



done_testing;
__END__
