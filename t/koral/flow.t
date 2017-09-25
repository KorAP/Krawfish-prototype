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
    $mb->a_fields('size', 'age'),
    $mb->a_frequencies,
    $mb->a_length,
  ),
  $mb->enrich(
    $mb->e_fields('age')
  ),
  $mb->sort_by(
    $mb->s_field('author')
  )
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
    $qb->anywhere,
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

is($koral->to_string, "meta=[aggr=[fields:['size','age'],freq,length],enrich=[fields:['age']],sort=[field='author'<]],corpus=[1880&author=Goethe],query=[[/b./|aa][]cc]", 'Serialization');

# Get the query
ok(my $query = $koral->to_query, 'Create complex query construct');

is($query->to_string, "sort(field='author'<,field='id'<:fields('age':aggr(length,freq,fields:['size','age']:filter(/b./|aa[]cc,1880&author=Goethe))))", 'Stringification');

# Identify
# ok($query = $query->identify($index->dict), 'Create complex query construct');
# is($query->to_string, "", 'Stringification');



done_testing;
__END__
