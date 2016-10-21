use Test::More;
use strict;
use warnings;
use Data::Dumper;

use_ok('Krawfish::Index');

my $index = Krawfish::Index->new('index.dat');

ok($index->add('t/data/doc1.jsonld'), 'Add new document');

# Get terms from the term dictionary
ok($index->dict->get('Der'), 'der is part of the term dict');
ok(!$index->dict->get('Haus'), 'Haus is not part of the term dict');

is_deeply($index->dict->get('Der')->{array}, [[0,0]], 'PostingsList');

ok($index->add('t/data/doc2.jsonld'), 'Add new document');

is_deeply($index->dict->get('Der')->{array}, [[0,0],[1,0]], 'PostingsList');
is_deeply($index->dict->get('Hut')->{array}, [[0,11],[1,1]], 'PostingsList');

# Index as data structure
$index->add(
  {
    doc => {
      annotation => [
        {
          '@type' => "koral:token",
          "key" => "Die"
        },
        {
          '@type' => "koral:token",
          "key" => "alte"
        },
        {
          '@type' => "koral:token",
          "key" => "Frau"
        }
      ]
    }
  }
);

is_deeply($index->dict->get('alte')->{array}, [[0,1],[2,1]], 'PostingsList');

done_testing;
