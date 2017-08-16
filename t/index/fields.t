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

is($fields[0]->[1], 2, 'Field id');
is($index->dict->term_by_term_id(2), '+docID:doc-3', 'Term');
is($fields[1]->[1], 4, 'Field id');
is($index->dict->term_by_term_id(4), '+license:closed', 'Term');
is($fields[2]->[1], 6, 'Field id');
is($index->dict->term_by_term_id(6), '+textLength:8', 'Term');
ok(!$fields[3]->[1], 'Field id');


ok($pointer = $index->segment->fields->pointer, 'Get pointer');
is($pointer->skip_doc(0), 0, 'Skip');

# Get the +license and +textLength fields
ok(@fields = $pointer->fields(3, 5, 17), 'Get fields');

is($fields[0]->[1], 4, 'Field id');
is($index->dict->term_by_term_id(4), '+license:closed', 'Term');
is($fields[1]->[1], 6, 'Field id');
is($index->dict->term_by_term_id(6), '+textLength:8', 'Term');
ok(!$fields[2], 'Field id');


ok($index = Krawfish::Index->new, 'Create new index');

ok_index($index, {
  id => 7,
  integer_size => 2,
} => [qw/aa bb/], 'Add complex document');

ok_index($index, {
  id => 3,
  integer_size => 3,
} => [qw/aa cc cc/], 'Add complex document');
ok_index($index, {
  id => 1,
  integer_size => 17,
} => [qw/aa bb/], 'Add complex document');

ok($pointer = $index->segment->fields->pointer, 'Get pointer');
is($pointer->skip_doc(0), 0, 'Skip');



# Get the +size value
ok(my @values = $pointer->values($index->dict->term_id_by_term('!size')),
   'Get field value');
is($values[0]->[1], 2, 'Size');


# Get +size of doc_id 2
is($pointer->skip_doc(2), 2, 'Skip');
ok(@values = $pointer->values($index->dict->term_id_by_term('!size')),
   'Get field value');

is($values[0]->[1], 17, 'Size');


done_testing;
__END__
