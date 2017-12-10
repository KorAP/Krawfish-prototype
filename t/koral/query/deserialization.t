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


# Check serialization and deserialization match
sub serialize_deserialize_ok {
  my $query = shift;
  my $serialized = $query->to_string;
  unless ($serialized) {
    fail('Query not serializable');
  };
  my $fragment = $query->to_koral_fragment;
  unless ($fragment) {
    fail('Fragment not generated');
  };
  my $deserialized = $importer->from_koral($fragment);
  unless ($deserialized) {
    fail('Fragment not deserializable');
  };
  is($deserialized->to_string, $serialized, 'Serialization is equal');
};


# Sequence, token, term, class(nr)
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

is($query->to_string, '[tt/p=NN]{2:[tt/p!=NN]}', 'Stringification');
serialize_deserialize_ok($query);

# Repetition, Span
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
      '@type' => 'koral:span',
      'wrap' => {
        '@type' => 'koral:term',
        'foundry' => 'cnx',
        'key' => 'NP',
        'layer' => 'c'
      }
    }
  ]
}), 'Import Repetition, Span, Term');

is($query->to_string, '<cnx/c=NP>{2,3}', 'Stringification');
serialize_deserialize_ok($query);


# Length, Token(termgroup), class(nonr)
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
        '@type' => 'koral:termGroup',
        'operation' => 'operation:and',
        'operands' => [
          {
            '@type' => 'koral:term',
            'foundry' => 'cnx',
            'key' => 'NP',
            'layer' => 'c'
          },
          {
            '@type' => 'koral:term',
            'foundry' => 'cnx',
            'key' => 'VP',
            'layer' => 'c'
          },
          {
            '@type' => 'koral:termGroup',
            'operation' => 'operation:or',
            'operands' => [
              {
                '@type' => 'koral:term',
                'foundry' => 'tt',
                'key' => 'NN',
                'layer' => 'p'
              },
              {
                '@type' => 'koral:term',
                'foundry' => 'opennlp',
                'key' => 'NN',
                'layer' => 'p'
              }
            ]
          }
        ]
      }
    }
  ]
}), 'Import Repetition, Span, Term');


is($query->to_string,
   '[cnx/c=NP&cnx/c=VP&(opennlp/p=NN|tt/p=NN)]{2,3}',
   'Stringification');

serialize_deserialize_ok($query);

done_testing;
__END__


diag 'Test deserialization failures';
# E.g.
#   - span without wrap
#   - termGroups
#     - without operation
#     - without operation but relation
#     - without operands
#     - with a single operand

done_testing;

__END__
