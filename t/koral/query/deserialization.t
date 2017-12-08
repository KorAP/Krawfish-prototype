use Test::More;
use strict;
use warnings;
use Mojo::JSON qw/encode_json decode_json/;
use Mojo::File;
use Data::Dumper;

use_ok('Krawfish::Koral::Query::Importer');

# deserialize import document
# my $doc_1 = slurp('t/data/doc1.jsonld');
# my $koral = Krawfish::Koral->new(decode_json($doc_1));


ok(my $importer = Krawfish::Koral::Query::Importer->new, 'New importer');

ok(my $query = $importer->from_koral(
  {
    '@type' => 'koral:group',
    'operation' => 'operation:sequence',
    'operands' => [
      {
        '@type' => 'koral:token',
        'wrap' => {
          '@type' => 'koral:term',
          'foundry' => 'tt',
          'key' => 'NN',
          'layer' => 'p',
          'match' => 'match:eq'
        }
      },{
        '@type' => 'koral:group',
        'classOut' => 2,
        'operation' => 'operation:class',
        'operands' => [
          {
            '@type' => 'koral:token',
            'wrap' => {
              '@type' => 'koral:term',
              'foundry' => 'tt',
              'key' => 'NN',
              'layer' => 'p',
              'match' => 'match:ne'
            }
          }
        ]
      }
    ]
  }
), 'Import Sequence, Token, Term, Class');

is(my $deserialized = $query->to_string, '[tt/p=NN]{2:[tt/p!=NN]}', 'Stringification');
ok(my $fragment = $query->to_koral_fragment, 'Get parsed fragment');
ok(my $serialized = $importer->from_koral($fragment), 'Parse serialization');
is($deserialized, $serialized->to_string, 'In/Out equivalence');


ok($query = $importer->from_koral({
  '@type' => 'koral:group',
  'operation' => 'operation:repetition',
  'boundary' => {
    '@type' => 'koral:boundary',
    min => 2,
    max => 3
  },
  'operands' => [
    {
      '@type' => 'koral:token',
      'wrap' => {
        '@type' => 'koral:term',
        'foundry' => 'tt',
        'key' => 'NN',
        'layer' => 'p'
      }
    }
  ]
}), 'Import Repetition, Token, Term');

is($deserialized = $query->to_string, '[tt/p=NN]{2,3}', 'Stringification');
ok($fragment = $query->to_koral_fragment, 'Get parsed fragment');
ok($serialized = $importer->from_koral($fragment), 'Parse serialization');
is($deserialized, $serialized->to_string, 'In/Out equivalence');


local $TODO = 'Test further';


done_testing;

__END__
