use Test::More;
use strict;
use warnings;

use Krawfish::Koral;
use Krawfish::Index;

# Add documents to index
my $index = Krawfish::Index->new;
$index->introduce_field('docID' => 'de_DE');
$index->add_doc('t/data/doc1.jsonld');
$index->add_doc('t/data/doc2.jsonld');
$index->commit;

# Start KoralQuery object
my $koral = Krawfish::Koral->new;

# Define a query
# [einen|"d.*"][][Hut]
my $query = $koral->query_builder;
$koral->query(
  $query->seq(
    $query->token(
      $query->bool_or(
        'einen',
        $query->term_re('d.*')
      )
    ),
    $query->anywhere,
    $query->term('Hut')
  )
);

# Define a virtual corpus
my $corpus = $koral->corpus_builder;
$koral->corpus(
  $corpus->bool_and(
    $corpus->string('license=free'),
    $corpus->string('corpus=corpus-2')
  )
);

# Define a compilation target
my $compile = $koral->compilation_builder;
$koral->compilation(
  $compile->aggregate(
    $compile->a_fields('license'),
    $compile->a_frequencies
  ),
  $compile->enrich(
    $compile->e_fields('textLength')
  ),
  $compile->sort_by(
    $compile->s_field('docID')
  )
);

my $request = $koral->to_query
  ->identify($index->dict)
  ->optimize($index->segment);

# TODO:
#   Serialize ->to_koral_query, that will

my $str = '';
if ($request->next) {
  $str .= $request->current_match->to_string;
};

# warn $request->collection->to_string;

is($str, '[0:9-12::H+s..gAA,-]');

done_testing;
__END__
