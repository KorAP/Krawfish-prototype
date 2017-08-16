use Test::More;
use Test::Krawfish;
use strict;
use warnings;

use_ok('Krawfish::Koral');
use_ok('Krawfish::Koral::Meta');
use_ok('Krawfish::Index');

# Create some documents
my $index = Krawfish::Index->new;
ok_index($index, {
  id => 2,
  author => 'Peter',
  genre => 'novel',
  age => 4
} => [qw/aa bb/], 'Add complex document');
ok_index($index, {
  id => 3,
  author => 'Peter',
  genre => 'novel',
  age => 3
} => [qw/aa bb/], 'Add complex document');
ok_index($index, {
  id => 5,
  author => 'Peter',
  genre => 'newsletter',
  title => 'Your way to success!',
  age => 4
} => [qw/aa bb/], 'Add complex document');
ok_index($index, {
  id => 6,
  author => 'Michael',
  genre => 'newsletter',
  age => 7
} => [qw/aa bb/], 'Add complex document');


my $koral = Krawfish::Koral->new;
my $mb = $koral->meta_builder;

# Introduce redundant operations and new sorts
$koral->meta(
  $mb->enrich(
    $mb->e_fields('author', 'title', 'id')
  )
);

$koral->query($koral->query_builder->token('a'));

# Get the meta object
my $meta = $koral->meta;

is($meta->to_string, "enrich=[fields:['author','title','id']]", 'Stringification');

# This will introduce a sort filter and reorder and simplify the operations
ok($meta = $meta->normalize, 'Normalize meta object');

is($meta->to_string, "enrich=[fields:['author','title','id']]",
   'Stringification');

ok($meta = $koral->to_query->identify($index->dict), 'Identification');

is($meta->to_string, "fields(#3,#7,#17:[0])",
   'Stringification');


# Introduce redundant operations and new sorts
$koral->meta(
  $mb->sort_by($mb->s_field('author', 1), $mb->s_field('age')),
  $mb->enrich($mb->e_fields('author', 'title', 'id')),
  $mb->sort_by($mb->s_field('length')),
  $mb->enrich($mb->e_fields('subTitle'))
);

# Get the meta object
$meta = $koral->meta;


# Translate to term_ids
# subtitle and length are not available for the fields
is(
  $meta->to_string,
  "sort=[field='author'>,field='age'<],enrich=[fields:['author','title','id']],sort=[field='length'<],enrich=[fields:['subTitle']]",
  'Stringification'
);


# This will introduce a sort filter and reorder and simplify the operations
ok($meta = $meta->normalize, 'Normalize meta object');

is(
  $meta->to_string,
  "sort=[field='author'>,field='age'<,field='length'<;sortFilter],enrich=[fields:['author','title','id','subTitle']]",
  'Stringification'
);

# This will translate all fields to 
ok(my $query = $koral->to_query->identify($index->dict), 'Translate to identifier');

is(
  $query->to_string,
  "sort(field=#3>,field=#1<;sortFilter:fields(#3,#7,#17:[0]))",
  'Stringification'
);


done_testing;
__END__



# Simple meta definition
$koral->meta(
  $koral->meta_builder->items_per_page(3)->field_sort_asc_by('author')
);

ok($koral = $koral->normalize, 'Normalization');

#is($koral->prepare_for($index)->to_string,
is($koral->to_string,
   q!resultLimit([0-3]:resultSorted(['author'<,'id'<],0-3:constr(pos=2:'Der','<>opennlp/c=NP')))!,
   'Stringification');




# Meta definition with start index
$koral->meta(
  $koral->meta_builder->items_per_page(5)->start_index(2)->field_sort_asc_by('author')
);



is($koral->prepare_for($index)->to_string,
   q!resultLimit([2-7]:resultSorted(['author'<,'id'<],0-7:constr(pos=2:'Der','<>opennlp/c=NP')))!,
   'Stringification');

# Meta definition with facets
$koral->meta(
  $koral->meta_builder->facets('author')->start_index(2)->field_sort_asc_by('author')
);

is($koral->prepare_for($index)->to_string,
   q!resultLimit([2-]:resultSorted(['author'<,'id'<]:aggregate([facet:'author']:constr(pos=2:'Der','<>opennlp/c=NP'))))!,
   'Stringification');

# Meta definition with facets (different order)
$koral->meta(
  $koral->meta_builder->start_index(2)->facets('author')->field_sort_asc_by('author')
);

is($koral->prepare_for($index)->to_string,
   q!resultLimit([2-]:resultSorted(['author'<,'id'<]:aggregate([facet:'author']:constr(pos=2:'Der','<>opennlp/c=NP'))))!,
   'Stringification');


# Meta definition with count
$koral->meta(
  $koral->meta_builder->count(1)
);

is($koral->prepare_for($index)->to_string,
   q!resultSorted(['id'<]:aggregate([count]:constr(pos=2:'Der','<>opennlp/c=NP')))!,
   'Stringification');


# Meta definition with length
$koral->meta(
  $koral->meta_builder->length(1)
);

is($koral->prepare_for($index)->to_string,
   q!resultSorted(['id'<]:aggregate([length]:constr(pos=2:'Der','<>opennlp/c=NP')))!,
   'Stringification');


done_testing;
__END__
