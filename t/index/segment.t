use Test::More;
use strict;
use warnings;

use_ok('Krawfish::Index');

ok(my $index = Krawfish::Index->new, 'Create new index object');

my $doc_id;

ok(defined ($doc_id = $index->add('t/data/doc1.jsonld')), 'Add new document');


sub _postings {
  my $term = shift;
  my $term_id = $index->dict->term_id_by_term($term) or return;
  return $index->segment->postings($term_id)->pointer;
};

# Get terms from the term dictionary
my $term_id;
ok($term_id = $index->dict->term_id_by_term('Der'), 'Get term id');
is($term_id, 9, 'Term id valid');

ok(!$index->dict->term_id_by_term('Haus'), 'Get term id');


is_deeply(_postings('Der')->list->{array}, [[0,0]], 'PostingsList');

my $seg = $index->segment;

is($seg->primary->get($doc_id, 0, 3), 'Der', 'Get primary');


ok($index->add('t/data/doc2.jsonld'), 'Add new document');

is_deeply(_postings('Der')->list->{array}, [[0,0],[1,0]], 'PostingsList');

is_deeply(_postings('Hut')->list->{array}, [[0,11],[1,1]], 'PostingsList');


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


is_deeply(_postings('alte')->list->{array}, [[0,1],[2,1]], 'PostingsList');

ok($index->add('t/data/doc3-segments.jsonld'), 'Add new document with segments');

is_deeply(_postings('Der')->list->{array}, [[0,0],[1,0]], 'PostingsList');
is_deeply(_postings('akron=Der')->list->{array}, [[3,0]], 'PostingsList');

is_deeply(_postings('akron=trug')->list->{array}, [[3,3]], 'PostingsList');
is_deeply(_postings('opennlp/p=V')->list->{array}, [[3,3]], 'PostingsList');


done_testing;

__END__
