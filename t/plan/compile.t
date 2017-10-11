use Test::More;
use Test::Krawfish;
use Krawfish::Util::Constants qw/:PREFIX/;
use strict;
use warnings;

use_ok('Krawfish::Koral');
use_ok('Krawfish::Koral::Compile');
use_ok('Krawfish::Index');

# Create some documents
my $index = Krawfish::Index->new;

ok($index->introduce_field('id', 'NUM'), 'Introduce field as sortable');
ok($index->introduce_field('age', 'NUM'), 'Introduce field as sortable');
ok($index->introduce_field('author', 'DE'), 'Introduce field as sortable');

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

$index->commit;

my $koral = Krawfish::Koral->new;
my $mb = $koral->compile_builder;

# Introduce redundant operations and new sorts
$koral->compile(
  $mb->enrich(
    $mb->e_fields('author', 'title', 'id')
  )
);

$koral->query($koral->query_builder->token('a'));

# Get the compile object
my $compile = $koral->compile;

is($compile->to_string, "enrich=[fields:['author','title','id']]", 'Stringification');

# This will introduce a sort filter and reorder and simplify the operations
ok($compile = $compile->normalize, 'Normalize compile object');

is($compile->to_string, "enrich=[fields:['author','title','id']]",
   'Stringification');

ok($compile = $koral->to_query->identify($index->dict), 'Identification');

is($compile->to_id_string, "fields(#1,#3,#17:[0])",
   'Stringification');

# Introduce redundant operations and new sorts
$koral->compile(
  $mb->sort_by($mb->s_field('author', 1), $mb->s_field('age')),
  $mb->enrich($mb->e_fields('author', 'title', 'id')),
  $mb->sort_by($mb->s_field('length')),
  $mb->enrich($mb->e_fields('subTitle'))
);

# Get the compile object
$compile = $koral->compile;


# Translate to term_ids
# subtitle and length are not available for the fields
is(
  $compile->to_string,
  "sort=[field='author'>,field='age'<],enrich=[fields:['author','title','id']],sort=[field='length'<],enrich=[fields:['subTitle']]",
  'Stringification'
);

# This will introduce a sort filter and reorder and simplify the operations
ok($compile = $compile->normalize, 'Normalize compile object');

is(
  $compile->to_string,
  "sort=[field='author'>,field='age'<,field='length'<,field='id'<],enrich=[fields:['author','title','id','subTitle']]",
  'Stringification'
);

# This will translate all fields to 
ok(my $query = $koral->to_query->identify($index->dict), 'Translate to identifier');

is(
  $query->to_id_string,
  'sort(field=#1<:sort(no=\'length\'<:sort(field=#2<:sort(field=#3>:fields(#1,#3,#17:[0])))))',
  'Stringification'
);

# Introduce snippet
$koral->compile(
  $mb->enrich(
    $mb->e_snippet(
      context => $mb->e_span_context(SPAN_PREF . 'opennlp/s=s', 0)
    )
  )
);

is($koral->compile->to_string,
   'enrich=[snippet=[left:span(opennlp/s=s,0),right:span(opennlp/s=s,0),hit]]',
   'stringification'
 );

is($koral->to_string,
   'compile=[enrich=[snippet=[left:span(opennlp/s=s,0),right:span(opennlp/s=s,0),hit]]],query=[[a]]',
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
$koral->compile(
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


