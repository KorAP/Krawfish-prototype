use Test::More;
use strict;
use warnings;
use Mojo::JSON qw/encode_json decode_json/;
use Mojo::File;
use Data::Dumper;

use_ok('Krawfish::Koral::Query');

# deserialize import document
# my $doc_1 = slurp('t/data/doc1.jsonld');
# my $koral = Krawfish::Koral->new(decode_json($doc_1));

my $query = Krawfish::Koral::Query->from_koral(
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
);




is(my $deserialized = $query->to_string, '[tt/p=NN]{2:[tt/p!=NN]}', 'Stringification');

ok(my $fragment = $query->to_koral_fragment, 'Get parsed fragment');

ok(my $serialized = Krawfish::Koral::Query->from_koral($fragment), 'Parse serialization');

is($deserialized, $serialized->to_string, 'In/Out equivalence');

TODO: {
  local $TODO = 'Test further'
};


done_testing;

__END__
