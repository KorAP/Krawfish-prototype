use Test::More;
use strict;
use warnings;
use Data::Dumper;

use_ok('Krawfish::Koral');
use_ok('Krawfish::Index');

my $index = Krawfish::Index->new;

ok(defined $index->add('t/data/doc1.jsonld'), 'Add new document');

my $koral = Krawfish::Koral->new;

my $builder = $koral->query_builder;

# Position planning
my $query = $builder->position(
  ['isAround'],
  $builder->span('opennlp/c=NP'),
  $builder->token('Der')
);
ok(!$query->is_any, 'Is any');
ok(!$query->is_optional, 'Isn\'t optional');
ok(!$query->is_null, 'Isn\'t null');
ok(!$query->is_negative, 'Isn\'t negative');
ok(!$query->is_extended, 'Isn\'t extended');
is($query->to_string, 'pos(128:<opennlp/c=NP>,[Der])', 'Stringification');
is($query->prepare_for($index)->to_string, 'pos(128:<opennlp/c=NP>,[Der])', 'Planned Stringification');

diag 'Test further';

done_testing;
__END__

