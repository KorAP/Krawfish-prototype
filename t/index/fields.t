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
ok($pointer->skip_doc(0), 'Skip');

ok(my @fields = $pointer->fields, 'Get fields');

is($fields[0], 2, 'Field id');
is($index->dict->term_by_term_id(2), '+docID:doc-3', 'Term');
is($fields[1], 4, 'Field id');
is($index->dict->term_by_term_id(4), '+license:closed', 'Term');
is($fields[2], 6, 'Field id');
is($index->dict->term_by_term_id(6), '+textLength:8', 'Term');
ok(!$fields[3], 'Field id');

done_testing;
__END__
