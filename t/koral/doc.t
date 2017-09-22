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


# TODO:
#   Maybe it's possible to implement
#   $doc->stream->to_primary
#is($doc->primary_data,
#   'Der alte Mann ging über die Straße. Er trug einen lustigen Hut.',
#   'That\'s the primary data'
# );

is(substr($doc->stream->to_string, 0, 40),
   q!(0)<>['Der';'Der'$1](1)< >['alte';'alte'!,
   'Get stream');

is($doc->fields->to_string,
   "'docID'='doc-1';'license'='free';'corpus'='corpus-2';'textLength'=12",
   'Fields');


# New document
ok($doc = Krawfish::Koral::Document->new(
  't/data/doc3-segments.jsonld'
), 'Load document');

#is($doc->primary_data,
#   'Der Bau-Leiter trug einen lustigen Bau-Helm.',
#   'That\'s the primary data'
# );

is(substr($doc->stream->to_string, 0, 100),
   q!(0)<>['Der';'akron=Der'$1;'<>akron/c=NP'$3](1)< >['Bau';'akron=Bau-Leiter'$3](2)<->['Leiter'](3)< >[!,
   'Get stream');


is($doc->fields->to_string, "'docID'='doc-3';'license'='closed';'textLength'=8;'URI'='http://korap.ids-mannheim.de/instance/example'", 'Fields');


my $index = Krawfish::Index->new;

ok($doc = $doc->identify($index->dict), 'Turn terms into term_ids');

is($doc->fields->to_string, "#1=#2;#3=#4;#5=#6(8);#7='http://korap.ids-mannheim.de/instance/example'", 'Fields');

is($doc->stream->to_string, q!(0)<>[#8;9$1;11$3](1)< >[#13;14$3](2)<->[#15](3)< >[#16;17$4;18$4](4)< >[#21;22$5;11$8](5)< >[#23;24$6](6)< >[#13;25$8](7)<->[#26](8)<.>['']!, 'Stream');

is($doc->to_string, q![#1=#2;#3=#4;#5=#6(8);#7='http://korap.ids-mannheim.de/instance/example'](0)<>[#8;9$1;11$3](1)< >[#13;14$3](2)<->[#15](3)< >[#16;17$4;18$4](4)< >[#21;22$5;11$8](5)< >[#23;24$6](6)< >[#13;25$8](7)<->[#26](8)<.>['']!, 'Stringification');

done_testing;
__END__
