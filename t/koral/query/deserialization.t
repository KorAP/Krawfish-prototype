use Test::More;
use strict;
use warnings;
use Mojo::JSON qw/encode_json decode_json/;
use Mojo::File;
use Data::Dumper;

use_ok('Krawfish::Koral::Query::Builder');

# deserialize import document
# my $doc_1 = slurp('t/data/doc1.jsonld');
# my $koral = Krawfish::Koral->new(decode_json($doc_1));

ok(my $qb = Krawfish::Koral::Query::Builder->new, 'New importer');


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
  my $deserialized = $qb->from_koral($fragment);
  unless ($deserialized) {
    fail('Fragment not deserializable');
  };
  is($deserialized->to_string, $serialized, 'Serialization is equal');
};


# group:sequence, token, term, group:class(nr)
ok(my $query = $qb->from_koral(
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

# group:repetition, span
ok($query = $qb->from_koral({
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


# group:length, termgroup, group:class(no nr)
ok($query = $qb->from_koral({
  '@type' => 'koral:group',
  'operation' => 'operation:length',
  'boundary' => {
    '@type' => 'koral:boundary',
    min => 2,
    max => 3
  },
  'operands' => [
    {
      '@type' => 'koral:group',
      'operation' => 'operation:class',
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
    }
  ]
}), 'Import Repetition, Span, Term');


is($query->to_string,
   'length(2-3:{1:[cnx/c=NP&cnx/c=VP&(opennlp/p=NN|tt/p=NN)]})',
   'Stringification');

serialize_deserialize_ok($query);


# group:exclusion
ok($query = $qb->from_koral({
  '@type' => 'koral:group',
  'operation' => 'operation:exclusion',
  'frame' => [
    'frames:overlapsRight',
    'frames:endsWith',
    'frames:isAround',
    'frames:overlapsLeft',
    'frames:startsWith',
    'frames:matches'
  ],
  'operands' => [
    {
      '@type' => 'koral:span',
      wrap => {
        '@type' => 'koral:term',
        'foundry' => 'cnx',
        'key' => 'VP',
        'layer' => 'c'
      },
    },
    {
      '@type' => 'koral:token',
      'wrap' => {
        '@type' => 'koral:term',
        'foundry' => 'tt',
        'key' => 'V',
        'layer' => 'p'
      },
    }
  ]
}), 'Import Repetition, Span, Term');


is($query->to_string,
   'excl(endsWith;isAround;matches;startsWith:<cnx/c=VP>,[tt/p=V])',
   'Stringification');

serialize_deserialize_ok($query);



# group:position, group:disjunction/or
ok($query = $qb->from_koral({
  '@type' => 'koral:group',
  'operation' => 'operation:position',
  'frames' => [
    'frames:overlapsRight',
    'frames:endsWith',
    'frames:isAround',
    'frames:overlapsLeft',
    'frames:startsWith',
    'frames:matches'
  ],
  'operands' => [
    {
      '@type' => 'koral:span',
      wrap => {
        '@type' => 'koral:term',
        'foundry' => 'cnx',
        'key' => 'VP',
        'layer' => 'c'
      },
    },
    {
      '@type' => 'koral:group',
      'operation' => 'operation:disjunction',
      operands => [
        {
          '@type' => 'koral:token',
          'wrap' => {
            '@type' => 'koral:term',
            'foundry' => 'tt',
            'key' => 'V',
            'layer' => 'p'
          },
        },
        {
          '@type' => 'koral:token',
          'wrap' => {
            '@type' => 'koral:term',
            'foundry' => 'opennlp',
            'key' => 'V',
            'layer' => 'p'
          },
        }
      ]
    }
  ]
}), 'Import Repetition, Span, Term');

is($query->to_string,
   'constr(pos=endsWith;isAround;matches;overlapsLeft;overlapsRight;startsWith:'.
     '<cnx/c=VP>,([opennlp/p=V])|([tt/p=V]))',
   'Stringification');

serialize_deserialize_ok($query);



# group:position, group:disjunction/or
ok($query = $qb->from_koral({
  '@type' => 'koral:group',
  'operation' => 'operation:constraint',
  'constraints' => [
    {
      '@type' => 'constraint:position',
      frames => ['frames:matches']
    },
    {
      '@type' => 'constraint:classBetween',
      'classOut' => 5
    },
    {
      '@type' => 'constraint:notBetween',
      'wrap' => {
        '@type' => 'koral:span',
        wrap => {
          '@type' => 'koral:term',
          foundry => 'corenlp',
          layer => 'p',
          key => 'V'
        }
      }
    },
    {
      '@type' => 'constraint:inBetween',
      'boundary' => {
        '@type' => 'koral:boundary',
        'min' => 3,
        'max' => 7
      }
    }

  ],
  'operands' => [{
      '@type' => 'koral:token',
      'wrap' => {
        '@type' => 'koral:term',
        'foundry' => 'tt',
        'key' => 'V',
        'layer' => 'p'
      },
    },{
      '@type' => 'koral:token',
      'wrap' => {
        '@type' => 'koral:term',
        'foundry' => 'opennlp',
        'key' => 'V',
        'layer' => 'p'
      },
    }
  ]
}), 'Import Repetition, Span, Term');


is($query->to_string,
   'constr(pos=matches,class=5,notBetween=<corenlp/p=V>,between=3-7:[tt/p=V],[opennlp/p=V])',
   'Stringification');

serialize_deserialize_ok($query);



# nowhere
ok($query = $qb->from_koral({
  '@type' => 'koral:nowhere'
}), 'Nowhere');

is($query->to_string,
   '[0]',
   'Stringification');

serialize_deserialize_ok($query);

# Term ID
ok($query = $qb->from_koral({
  '@type' => 'koral:token',
  'wrap' => {
    '@type' => 'koral:term',
    '@id' => 'term:15'
  }
}), 'Term identifier');

is($query->to_string,
   '[#15]',
   'Stringification');

serialize_deserialize_ok($query);



# Unique
ok($query = $qb->from_koral({
  '@type' => 'koral:group',
  'operation' => 'operation:unique',
  'operands' => [
    {
      '@type' => 'koral:token',
      'wrap' => {
        '@type' => 'koral:term',
        'foundry' => 'opennlp',
        'key' => 'V',
        'layer' => 'p'
      },
    }
  ]
}), 'Term identifier');

is($query->to_string,
   'unique([opennlp/p=V])',
   'Stringification');

serialize_deserialize_ok($query);



# match
ok($query = $qb->from_koral({
  '@type' => 'koral:match',
  '@id' => 'match:doc-1/p0-1_h(1)1-2_h(2)1-2_c5_c8'
}), 'Import Repetition, Span, Term');

is($query->to_string,
   '[[id=doc-1:0-1!5,8$0,1,1,2|0,2,1,2]]',
   'Stringification');

serialize_deserialize_ok($query);



diag 'Test deserialization failures';
# E.g.
#   - span without wrap
#   - termGroups
#     - without operation
#     - without operation but relation
#     - without operands
#     - with a single operand
#   - opreration:position & operation:exclusion
#     - frames are not lists
#     - operands != 2

done_testing;

__END__
