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

my $seq = $builder->seq(
  $builder->token('Der'),
  $builder->token,
  $builder->span('opennlp/c=NP')
);

is($seq->to_string, '[Der][]<opennlp/c=NP>', 'Stringification');
ok(!$seq->is_null, 'Query is not null');
is($seq->to_string, '[Der][]<opennlp/c=NP>', 'Stringification');

TODO: {
  local $TODO = "Test further";
};

# aa []* bb
# aa []+ bb
# aa ([][])+ bb -> pos(frames=precedes,dist=???)
# -> constr(frames=precedes,dist=,2,100,steps=2:'aa', 'bb')
# aa ([opennlp][])+ bb
# aa ({1:[]{2}}|2:[]{3})+ bb

done_testing;

__END__



