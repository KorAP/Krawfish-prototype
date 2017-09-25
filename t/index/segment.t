use Test::More;
use Test::Krawfish;
use Krawfish::Util::Constants qw/:PREFIX/;
use strict;
use warnings;

use_ok('Krawfish::Index');

ok(my $index = Krawfish::Index->new, 'Create new index object');

ok_index_file($index,'doc1.jsonld', 'Add new document');

sub _postings {
  my $term = shift;
  my $term_id = $index->dict->term_id_by_term(TOKEN_PREF . $term) or return;
  return $index->segment->postings($term_id)->pointer;
};

# Get terms from the term dictionary
my $term_id;
ok($term_id = $index->dict->term_id_by_term(TOKEN_PREF . 'Der'), 'Get term id');
is($term_id, 10, 'Term id valid');

ok(!$index->dict->term_id_by_term('Haus'), 'Get term id');


is_deeply(_postings('Der')->{list}->{array}, [[0, 0, 1]], 'PostingsList');

my $seg = $index->segment;

# is($seg->primary->get($doc_id, 0, 3), 'Der', 'Get primary');

ok_index_file($index,'doc2.jsonld', 'Add new document');


is_deeply(_postings('Der')->{list}->{array}, [[0,0,1],[1,0,1]], 'PostingsList');

is_deeply(_postings('Hut')->{list}->{array}, [[0,11,12],[1,1,2]], 'PostingsList');


# Index as data structure
ok_index_koral($index,
  {
    '@context' => 'http://korap.ids-mannheim.de/ns/koral/0.3/context.jsonld',
    document => {
      'primaryData' => 'Die alte Frau',
      annotations => [
        {
          '@type' => "koral:token",
          offsets => [0,3],
          wrap => {
            '@type' => "koral:term",
            "key" => "Die"
          }
        },
        {
          '@type' => "koral:token",
          offsets => [4,8],
          wrap => {
            '@type' => "koral:term",
            "key" => "alte"
          }
        },
        {
          '@type' => "koral:token",
          offsets => [9,13],
          wrap => {
            '@type' => "koral:term",
            "key" => "Frau"
          }
        }
      ]
    }
  }
);

is_deeply(_postings('alte')->{list}->{array}, [[0,1,2],[2,1,2]], 'PostingsList');

ok_index_file($index,'doc3-segments.jsonld', 'Add new document with segments');

is_deeply(_postings('Der')->{list}->{array}, [[0,0,1],[1,0,1]], 'PostingsList');
is_deeply(_postings('akron=Der')->{list}->{array}, [[3,0,1]], 'PostingsList');

is_deeply(_postings('akron=trug')->{list}->{array}, [[3,3,4]], 'PostingsList');
is_deeply(_postings('opennlp/p=V')->{list}->{array}, [[3,3,4]], 'PostingsList');

done_testing;

__END__
