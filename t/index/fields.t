use strict;
use warnings;
use utf8;
use Test::More;
use Test::Krawfish;
use Krawfish::Util::Constants ':PREFIX';
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

is($index->dict->term_by_term_id(2), FIELD_PREF . 'docID:doc-3', 'Term');
is($fields[1]->term_id, 4, 'Field id');
is($index->dict->term_by_term_id(4), FIELD_PREF . 'license:closed', 'Term');
is($fields[2]->term_id, 6, 'Field id');
is($index->dict->term_by_term_id(6), FIELD_PREF . 'textLength:8', 'Term');
ok($fields[3], 'Field id');
ok(!$fields[3]->term_id, 'No field id');
is($fields[3]->value, 'http://korap.ids-mannheim.de/instance/example', 'No field id');
ok(!$fields[4], 'No more fields');

ok($pointer = $index->segment->fields->pointer, 'Get pointer');
is($pointer->skip_doc(0), 0, 'Skip');

# Get the +license and +textLength fields
ok(@fields = $pointer->fields(3, 5, 17), 'Get fields');

is($fields[0]->term_id, 4, 'Field id');
is($index->dict->term_by_term_id(4), FIELD_PREF . 'license:closed', 'Term');
is($fields[1]->term_id, 6, 'Field id');
is($index->dict->term_by_term_id(6), FIELD_PREF . 'textLength:8', 'Term');
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
ok(my @values = $pointer->int_fields($index->dict->term_id_by_term(KEY_PREF . 'size')),
   'Get field value');
is($values[0]->value, 2, 'Size');

# Get +size of doc_id 2
is($pointer->skip_doc(2), 2, 'Skip');
ok(@values = $pointer->int_fields($index->dict->term_id_by_term(KEY_PREF . 'size')),
   'Get field value');

is($values[0]->value, 17, 'Size');


ok($pointer = $index->segment->fields->pointer, 'Get pointer');
is($pointer->skip_doc(0), 0, 'Skip');

ok(@fields = $pointer->fields($index->dict->term_id_by_term(KEY_PREF . 'uri')), 'Get fields');
is($fields[0]->value, 'https://korap.ids-mannheim.de/instance/example7', 'Field id');



# Ranks for author

# This will commit rank data
ok($index->commit, 'Commit data');

ok(my $term_id = $index->dict->term_id_by_term(KEY_PREF . 'author'), 'Get term id');

ok(my $ranks = $index->segment->field_ranks->by($term_id), 'Get ranks');

is($ranks->to_string, '[1][2][0]', 'Get rank file');


my $dir = $ranks->ascending;
is($dir->rank_for(0), 3, 'Get ascending rank');
is($dir->rank_for(1), 1, 'Get ascending rank');
is($dir->rank_for(2), 2, 'Get ascending rank');

$dir = $ranks->descending;
is($dir->rank_for(0), 1, 'Get descending rank');
is($dir->rank_for(1), 3, 'Get descending rank');
is($dir->rank_for(2), 2, 'Get descending rank');

# Numerical ranks for size
ok($term_id = $index->dict->term_id_by_term(KEY_PREF . 'size'), 'Get term id');
ok($ranks = $index->segment->field_ranks->by($term_id), 'Get ranks');

is($ranks->to_string, '[0][1][2]', 'Get rank file');

$dir = $ranks->ascending;
is($dir->rank_for(0), 1, 'Get ascending rank');
is($dir->rank_for(1), 2, 'Get ascending rank');
is($dir->rank_for(2), 3, 'Get ascending rank');

$dir = $ranks->descending;
is($dir->rank_for(0), 3, 'Get descending rank');
is($dir->rank_for(1), 2, 'Get descending rank');
is($dir->rank_for(2), 1, 'Get descending rank');


# New index with multivalued fields
ok($index = Krawfish::Index->new, 'Create new index');

# Make this field sortable
ok($index->introduce_field('author', 'DE'), 'Introduce field as sortable');

ok_index($index, {
  author => 'Carol',
  title => 'My thesis'
} => [qw/aa bb/], 'Add complex document');

ok_index($index, {
  author => ['Amy', 'Mike'],
  title => 'A first attempt'
} => [qw/aa cc cc/], 'Add complex document');

ok_index($index, {
  author => 'Bob',
  title => 'To make it short ...'
} => [qw/aa bb/], 'Add complex document');

# Ranks for author
ok($index->commit, 'Commit data');
ok($term_id = $index->dict->term_id_by_term(KEY_PREF . 'author'), 'Get term id');
ok($ranks = $index->segment->field_ranks->by($term_id), 'Get ranks');

ok($pointer = $index->segment->fields->pointer, 'Get pointer');
ok(!$pointer->fields($index->dict->term_id_by_term(KEY_PREF . 'author')), 'Not fine');
is($pointer->skip_doc(0), 0, 'Skip');
ok(@fields = $pointer->fields($index->dict->term_id_by_term(KEY_PREF . 'author')), 'Fields');
is($fields[0]->term_id, 2, 'Field id');
ok(!$fields[1], 'Field id');

my $dict = $index->dict;

is($pointer->skip_doc(1), 1, 'Skip');
ok(@fields = $pointer->fields(
  $dict->term_id_by_term(KEY_PREF . 'author'),
  $dict->term_id_by_term(KEY_PREF . 'title')
), 'Fields');

is($fields[0]->key_id, 1, 'Key id');
is($fields[0]->term_id, 9, 'Field id');
is($dict->term_by_term_id(9), FIELD_PREF . 'author:Amy', 'Key');

is($fields[1]->key_id, 1, 'Key id');
is($fields[1]->term_id, 10, 'Field id');
is($dict->term_by_term_id(10), FIELD_PREF . 'author:Mike', 'Key');

is($fields[2]->key_id, 3, 'Key id');
is($fields[2]->term_id, 11, 'Field id');
is($dict->term_by_term_id(11), FIELD_PREF . 'title:A first attempt', 'Key');

ok(!$fields[3], 'Field id');

# This lists the sorted keys (therefore 4)
# with associated docs (therefore 1 is listed twice)
is($ranks->to_string, '[1][2][0][1]', 'Get rank file');

# The ascending rank takes Amy
$dir = $ranks->ascending;
is($dir->rank_for(0), 3, 'Get ascending rank');
is($dir->rank_for(1), 1, 'Get ascending rank');
is($dir->rank_for(2), 2, 'Get ascending rank');

# The descending rank takes 'Mike'
$dir = $ranks->descending;
is($dir->rank_for(0), 2, 'Get descending rank');
is($dir->rank_for(1), 1, 'Get descending rank');
is($dir->rank_for(2), 3, 'Get descending rank');



# Create new document
$index = Krawfish::Index->new;
ok($index->introduce_field('id', 'NUM'), 'Introduce field as sortable');
ok_index($index, {
  id => 2,
} => [qw/aa bb/], 'Add complex document');
ok_index($index, {
  id => 3,
} => [qw/aa bb/], 'Add complex document');
ok_index($index, {
  id => 1,
} => [qw/aa bb aa/], 'Add complex document');
ok_index($index, {
  id => 6,
} => [qw/bb/], 'Add complex document');
ok_index($index, {
  id => 5,
} => [qw/aa bb/], 'Add complex document');
ok($index->commit, 'Commit data');

# The numerical ascending ranks of 'id'
ok($term_id = $index->dict->term_id_by_term(KEY_PREF . 'id'), 'Get term id');
ok($ranks = $index->segment->field_ranks->by($term_id), 'Get ranks');
$dir = $ranks->ascending;
is($dir->rank_for(2), 1, 'Get ascending rank');
is($dir->rank_for(0), 2, 'Get ascending rank');
is($dir->rank_for(1), 3, 'Get ascending rank');
is($dir->rank_for(4), 4, 'Get ascending rank');
is($dir->rank_for(3), 5, 'Get ascending rank');


done_testing;
__END__

