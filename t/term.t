use Test::More;
use strict;
use warnings;
use Data::Dumper;

use_ok('Krawfish::Index::Term');

my $term = Krawfish::Index::Term->new('baum');
ok(!$term->field,   'No field');
ok(!$term->prefix,  'No prefix');
ok(!$term->foundry, 'No foundry');
ok(!$term->layer,   'No layer');
is($term->key, 'baum', 'Key');
ok(!$term->value,   'No value');

$term = Krawfish::Index::Term->new('<>baum');
ok(!$term->field,   'No field');
is($term->prefix, '<>', 'Prefix');
ok(!$term->foundry, 'No foundry');
ok(!$term->layer,   'No layer');
is($term->key, 'baum', 'Key');
ok(!$term->value,   'No value');

$term = Krawfish::Index::Term->new('opennlp=baum');
ok(!$term->field,   'No field');
ok(!$term->prefix,  'No prefix');
is($term->foundry, 'opennlp', 'Foundry');
ok(!$term->layer,   'No layer');
is($term->key, 'baum', 'Key');
ok(!$term->value,   'No value');

$term = Krawfish::Index::Term->new('opennlp/c=baum');
ok(!$term->field,   'No field');
ok(!$term->prefix,  'No prefix');
is($term->foundry, 'opennlp', 'Foundry');
is($term->layer, 'c', 'Layer');
is($term->key, 'baum', 'Key');
ok(!$term->value,   'No value');

$term = Krawfish::Index::Term->new('opennlp/p=gender:m');
ok(!$term->field, 'No field');
ok(!$term->prefix, 'No prefix');
is($term->foundry, 'opennlp', 'Foundry');
is($term->layer, 'p', 'Layer');
is($term->key, 'gender', 'Key');
is($term->value, 'm', 'Value');

done_testing;
__END__
