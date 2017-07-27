use Test::More;
use strict;
use warnings;

use_ok('Krawfish::Koral');

my $koral = Krawfish::Koral->new;

my $qb = $koral->query_builder;
my $cb = $koral->corpus_builder;
my $mb = $koral->meta_builder;

# Create meta
$koral->meta(
  $mb->aggregate(
    $mb->a_facets('size', 'age'),
    $mb->a_frequencies,
    $mb->a_length,
  ),
  $mb->fields('age'),
  $mb->sort_by('author')
);

# Create query
$koral->query(
  $qb->seq(
    $qb->token(
      $qb->bool_or(
        'aa',
        $qb->term_re('b.')
      )
    ),
    $qb->any,
    $qb->term('cc')
  )
);

# Create virtual corpus
$koral->corpus(
  $cb->bool_and(
    $cb->string('author=Goethe'),
    $cb->date('1880')
  )
);

# Get the query
# ok(my $query = $koral->to_nodes, 'Create complex query construct');


done_testing;
__END__
