use strict;
use warnings;
use utf8;
use Test::More;
use Test::Krawfish;
use Data::Dumper;

use_ok('Krawfish::Koral::Document');
use_ok('Krawfish::Koral');
use_ok('Krawfish::Index');


# Add some data
ok(my $doc = Krawfish::Koral::Document->new(
  't/data/doc3-segments.jsonld'
), 'Load document');

ok(my $index = Krawfish::Index->new, 'Create new index');

# Transform dictionary to term_id stream
ok($doc = $doc->identify($index->dict), 'Translate to term identifiers');

# Add document to segment
my $doc_id = $index->segment->add($doc);
is($doc_id, 0, 'Doc id well added');

ok(my $pointer = $index->segment->fields->pointer, 'Get pointer');
is($pointer->skip_doc(0), 0, 'Skip');

ok(my @fields = $pointer->fields, 'Get fields');

is($fields[0]->term_id, 2, 'Field id');

is($index->dict->term_by_term_id(2), '+docID:doc-3', 'Term');
is($fields[1]->term_id, 4, 'Field id');
is($index->dict->term_by_term_id(4), '+license:closed', 'Term');
is($fields[2]->term_id, 6, 'Field id');
is($index->dict->term_by_term_id(6), '+textLength:8', 'Term');
ok($fields[3], 'Field id');
ok(!$fields[3]->term_id, 'No field id');
is($fields[3]->value, 'http://korap.ids-mannheim.de/instance/example', 'No field id');
ok(!$fields[4], 'No more fields');

ok($pointer = $index->segment->fields->pointer, 'Get pointer');
is($pointer->skip_doc(0), 0, 'Skip');

# Get the +license and +textLength fields
ok(@fields = $pointer->fields(3, 5, 17), 'Get fields');

is($fields[0]->term_id, 4, 'Field id');
is($index->dict->term_by_term_id(4), '+license:closed', 'Term');
is($fields[1]->term_id, 6, 'Field id');
is($index->dict->term_by_term_id(6), '+textLength:8', 'Term');
ok(!$fields[2], 'Field id');




ok($index = Krawfish::Index->new, 'Create new index');

# Make this field sortable
ok($index->introduce_field('author', 'DE'), 'Introduce field as sortable');
ok($index->introduce_field('size', 'NUM'), 'Introduce field as sortable');

ok_index($index, {
  id => 7,
  author => 'Carol',
  integer_size => 2,
  store_uri => 'https://korap.ids-mannheim.de/instance/example7'
} => [qw/aa bb/], 'Add complex document');

ok_index($index, {
  id => 3,
  author => 'Amy',
  integer_size => 3,
  store_uri => 'https://korap.ids-mannheim.de/instance/example3'
} => [qw/aa cc cc/], 'Add complex document');
ok_index($index, {
  id => 1,
  author => 'Bob',
  integer_size => 17,
  store_uri => 'https://korap.ids-mannheim.de/instance/example1'
} => [qw/aa bb/], 'Add complex document');


ok($pointer = $index->segment->fields->pointer, 'Get pointer');
is($pointer->skip_doc(0), 0, 'Skip');


# Get the +size value
ok(my @values = $pointer->values($index->dict->term_id_by_term('!size')),
   'Get field value');
is($values[0]->value, 2, 'Size');

# Get +size of doc_id 2
is($pointer->skip_doc(2), 2, 'Skip');
ok(@values = $pointer->values($index->dict->term_id_by_term('!size')),
   'Get field value');

is($values[0]->value, 17, 'Size');


ok($pointer = $index->segment->fields->pointer, 'Get pointer');
is($pointer->skip_doc(0), 0, 'Skip');

ok(@fields = $pointer->fields($index->dict->term_id_by_term('!uri')), 'Get fields');
is($fields[0]->value, 'https://korap.ids-mannheim.de/instance/example7', 'Field id');



# Ranks for author

# This will commit rank data
ok($index->commit, 'Commit data');

ok(my $term_id = $index->dict->term_id_by_term('!author'), 'Get term id');
ok(my $ranks = $index->segment->field_ranks->by($term_id), 'Get ranks');

is($ranks->to_string, '[1][2][0]', 'Get rank file');

is($ranks->asc_rank(0), 3, 'Get ascending rank');
is($ranks->asc_rank(1), 1, 'Get ascending rank');
is($ranks->asc_rank(2), 2, 'Get ascending rank');

is($ranks->desc_rank(0), 1, 'Get descending rank');
is($ranks->desc_rank(1), 3, 'Get descending rank');
is($ranks->desc_rank(2), 2, 'Get descending rank');


# Numerical ranks for size
ok($term_id = $index->dict->term_id_by_term('!size'), 'Get term id');
ok($ranks = $index->segment->field_ranks->by($term_id), 'Get ranks');

is($ranks->to_string, '[0][1][2]', 'Get rank file');

is($ranks->asc_rank(0), 1, 'Get ascending rank');
is($ranks->asc_rank(1), 2, 'Get ascending rank');
is($ranks->asc_rank(2), 3, 'Get ascending rank');

is($ranks->desc_rank(0), 3, 'Get descending rank');
is($ranks->desc_rank(1), 2, 'Get descending rank');
is($ranks->desc_rank(2), 1, 'Get descending rank');



# New index with multivalued fields
ok($index = Krawfish::Index->new, 'Create new index');

# Make this field sortable
ok($index->introduce_field('author', 'DE'), 'Introduce field as sortable');

ok_index($index, {
  author => 'Carol',
} => [qw/aa bb/], 'Add complex document');

ok_index($index, {
  author => ['Amy', 'Mike'],
} => [qw/aa cc cc/], 'Add complex document');

ok_index($index, {
  author => 'Bob',
} => [qw/aa bb/], 'Add complex document');

# Ranks for author
ok($index->commit, 'Commit data');
ok($term_id = $index->dict->term_id_by_term('!author'), 'Get term id');
ok($ranks = $index->segment->field_ranks->by($term_id), 'Get ranks');

# This lists the sorted keys (therefore 4)
# with associated docs (therefore 1 is listed twice)
is($ranks->to_string, '[1][2][0][1]', 'Get rank file');


# The ascending rank takes Amy
is($ranks->asc_rank(0), 3, 'Get ascending rank');
is($ranks->asc_rank(1), 1, 'Get ascending rank');
is($ranks->asc_rank(2), 2, 'Get ascending rank');

# The descending rank takes 'Mike'
is($ranks->desc_rank(0), 2, 'Get descending rank');
is($ranks->desc_rank(1), 1, 'Get descending rank');
is($ranks->desc_rank(2), 3, 'Get descending rank');



done_testing;
__END__

