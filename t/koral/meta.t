use Test::More;
use strict;
use warnings;

use_ok('Krawfish::Koral::Meta::Builder');
use_ok('Krawfish::Koral::Meta');

my $mb = Krawfish::Koral::Meta::Builder->new;

# Build aggregations
ok(my $meta = $mb->aggregate( $mb->a_frequencies ), 'Add aggregation');
is($meta->to_string, 'aggr=[freq]', 'Stringification');

ok($meta = $mb->aggregate(
  $mb->a_facets('size', 'age'),
  $mb->a_frequencies,
  $mb->a_length
), 'Add aggregation');
is($meta->to_string, "aggr=[facets:['size','age'],freq,length]", 'Stringification');

ok($meta = $mb->enrich(
  $mb->e_fields('author', 'title', 'id')
), 'Create fields');
is($meta->to_string, "enrich=[fields:['author','title','id']]", 'Stringification');


# Build sorting
ok($meta = $mb->sort_by($mb->s_field('author', 1), $mb->s_field('age')), 'Create fields');
is($meta->to_string, "sort=[field='author'>,field='age'<]", 'Stringification');


my $meta_koral = Krawfish::Koral::Meta->new(
  $mb->sort_by($mb->s_field('author', 1), $mb->s_field('age')),
  $mb->enrich($mb->e_fields('author', 'title', 'id'))
);


is(
  $meta_koral->to_string,
  "sort=[field='author'>,field='age'<],enrich=[fields:['author','title','id']]",
  'Stringification'
);


# Introduce redundant operations and new sorts
$meta_koral = Krawfish::Koral::Meta->new(
  $mb->sort_by($mb->s_field('author', 1), $mb->s_field('age')),
  $mb->enrich($mb->e_fields('author', 'title', 'id')),
  $mb->sort_by($mb->s_field('length')),
  $mb->enrich($mb->e_fields('subTitle'))
);


is(
  $meta_koral->to_string,
  "sort=[field='author'>,field='age'<],enrich=[fields:['author','title','id']],sort=[field='length'<],enrich=[fields:['subTitle']]",
  'Stringification'
);


# This will introduce a sort filter and reorder and simplify the operations
ok($meta_koral = $meta_koral->normalize, 'Normalize meta object');

is(
  $meta_koral->to_string,
  "sort=[field='author'>,field='age'<,field='length'<;sortFilter],enrich=[fields:['author','title','id','subTitle']]",
  'Stringification'
);


# Check normalization of aggregate functions
$meta_koral = Krawfish::Koral::Meta->new(
  $mb->aggregate(
    $mb->a_length,
    $mb->a_facets('author', 'age'),
    $mb->a_frequencies,
    $mb->a_facets('corpus', 'age')
  )
);

ok($meta_koral = $meta_koral->normalize, 'Normalization');

is($meta_koral->to_string,
   "aggr=[length,freq,facets:['author','age','corpus']]",
   'stringification');

done_testing;

__END__;
