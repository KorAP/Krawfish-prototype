use Test::More;
use strict;
use warnings;
use Data::Dumper;

use_ok('Krawfish::Index');

my $index = Krawfish::Index->new('index.dat');

my $doc_id;
ok(defined ($doc_id = $index->add('t/data/doc1.jsonld')), 'Add new document');

# Get terms from the term dictionary
ok($index->dict->pointer('Der'), 'der is part of the term dict');
ok(!$index->dict->pointer('Haus'), 'Haus is not part of the term dict');

is_deeply($index->dict->pointer('Der')->list->{array}, [[0,0]], 'PostingsList');

is($index->primary->get($doc_id, 0, 3), 'Der', 'Get primary');

ok($index->add('t/data/doc2.jsonld'), 'Add new document');

is_deeply($index->dict->pointer('Der')->list->{array}, [[0,0],[1,0]], 'PostingsList');
is_deeply($index->dict->pointer('Hut')->list->{array}, [[0,11],[1,1]], 'PostingsList');

# Index as data structure
$index->add(
  {
    document => {
      annotations => [
        {
          '@type' => "koral:token",
          wrap => {
            "key" => "Die"
          }
        },
        {
          '@type' => "koral:token",
          wrap => {
            "key" => "alte"
          }
        },
        {
          '@type' => "koral:token",
          wrap => {
            "key" => "Frau"
          }
        }
      ]
    }
  }
);

is_deeply($index->dict->pointer('alte')->list->{array}, [[0,1],[2,1]], 'PostingsList');

ok($index->add('t/data/doc3-segments.jsonld'), 'Add new document with segments');

is_deeply($index->dict->pointer('Der')->list->{array}, [[0,0],[1,0]], 'PostingsList');
is_deeply($index->dict->pointer('akron=Der')->list->{array}, [[3,0]], 'PostingsList');

is_deeply($index->dict->pointer('akron=trug')->list->{array}, [[3,3]], 'PostingsList');
is_deeply($index->dict->pointer('opennlp/p=V')->list->{array}, [[3,3]], 'PostingsList');

done_testing;
