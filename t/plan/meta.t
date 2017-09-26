use Test::More;
use Test::Krawfish;
use Krawfish::Util::Constants qw/:PREFIX/;
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
  "sort=[field='author'>,field='age'<,field='length'<,field='id'<],enrich=[fields:['author','title','id','subTitle']]",
  'Stringification'
);

# This will translate all fields to 
ok(my $query = $koral->to_query->identify($index->dict), 'Translate to identifier');

is(
  $query->to_string,
  'sort(field=#7<:sort(field=#1<:sort(field=#3>:fields(#3,#7,#17:[0]))))',
  'Stringification'
);


# Introduce snippet
$koral->meta(
  $mb->enrich(
    $mb->e_snippet(
      context => $mb->e_span_context(SPAN_PREF . 'opennlp/s=s', 0)
    )
  )
);

is($koral->meta->to_string,
   'enrich=[snippet=[left:span(opennlp/s=s,0),right:span(opennlp/s=s,0),hit]]',
   'stringification'
 );

is($koral->to_string,
   'meta=[enrich=[snippet=[left:span(opennlp/s=s,0),right:span(opennlp/s=s,0),hit]]],query=[[a]]',
   'stringification');

$query = $koral->to_query;
is($query->to_string, 'snippet(left=span(opennlp/s=s,0),right=span(opennlp/s=s,0),hit:filter(a,[1]))', 'Stringification');

# The element doesn't exist, so the context is ignored
$query = $query->identify($index->dict);
is($query->to_string, 'snippet(hit:[0])', 'Stringification');


# Add new document
ok_index($index, {
  id => 7,
  author => 'Stefan',
  genre => 'novel',
  age => 19
} => '<1:xy>[aa]<2:opennlp/s=s>[aa]</1>[corenlp/c=cc|dd][aa]</2>', 'Add complex document');


# Introduce snippet
$koral->meta(
  $mb->enrich(
    $mb->e_snippet(
      context => $mb->e_span_context(SPAN_PREF . 'opennlp/s=s', 0)
    )
  )
);

ok($query = $koral->to_query->identify($index->dict), 'Create query');

# Better not check term ids ...
is($query->to_string, 'snippet(left=span(#27/#28=#26,0),right=span(#27/#28=#26,0),hit:[0])', 'Stringification');



done_testing;
__END__


