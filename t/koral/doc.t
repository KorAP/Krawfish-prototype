use strict;
use warnings;
use utf8;
use Test::More;
use Test::Krawfish;
use Data::Dumper;

# TODO: Move this to Koral::Document
use_ok('Krawfish::Koral::Document');
use_ok('Krawfish::Index');

ok(my $doc = Krawfish::Koral::Document->new(
  't/data/doc1.jsonld'
), 'Load document');

is($doc->primary_data,
   'Der alte Mann ging über die Straße. Er trug einen lustigen Hut.',
   'That\'s the primary data'
 );

is(substr($doc->stream->to_string, 0, 40),
   q!(0)['Der';'#Der'$0](1) ['alte';'#alte'$0!,
   'Get stream');

is($doc->fields->to_string,
   "'docID'='doc-1';'license'='free';'corpus'='corpus-2';'textLength'=12",
   'Fields');


# New document
ok($doc = Krawfish::Koral::Document->new(
  't/data/doc3-segments.jsonld'
), 'Load document');

is($doc->primary_data,
   'Der Bau-Leiter trug einen lustigen Bau-Helm.',
   'That\'s the primary data'
 );

is(substr($doc->stream->to_string, 0, 100),
   q!(0)['Der';'#akron=Der'$0;'<>akron/c=NP'$2](1) ['Bau';'#akron=Bau-Leiter'$1](2)-['Leiter'](3) ['trug'!,
   'Get stream');

is($doc->fields->to_string, "'docID'='doc-3';'license'='closed';'textLength'=8", 'Fields');


my $index = Krawfish::Index->new;

ok($doc = $doc->identify($index->dict), 'Turn terms into term_ids');

is($doc->fields->to_string, '1=2;3=4;5=6(8)', 'Fields');

is($doc->stream->to_string, '(0)[7;8$0;9$2](1) [10;11$1](2)-[12](3) [13;14$0;15$0](4) [16;17$0;9$3](5) [18;19$0](6) [10;20$1](7)-[21](8).[22]', 'Stream');

is($doc->to_string, '[1=2;3=4;5=6(8)](0)[7;8$0;9$2](1) [10;11$1](2)-[12](3) [13;14$0;15$0](4) [16;17$0;9$3](5) [18;19$0](6) [10;20$1](7)-[21](8).[22]', 'Stringification');

done_testing;
__END__
