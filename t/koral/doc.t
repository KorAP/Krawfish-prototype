use strict;
use warnings;
use utf8;
use Test::More;
use Krawfish::Util::Constants qw/:PREFIX/;
use Test::Krawfish;
use Data::Dumper;

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
   q!(0)<>['Der';'! . TOKEN_PREF . q!Der'$1](1)< >['alte';'! . TOKEN_PREF . q!alt!,
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
   q!(0)<>['Der';'! . TOKEN_PREF . q!akron=Der'$1;'! .SPAN_PREF. q!akron/c=NP'$3](1)< >['Bau';'! . TOKEN_PREF . q!akron=Bau-Leiter'$3](2)<->['Leiter'](3)< >!,
   'Get stream');

is($doc->fields->to_string, "'docID'='doc-3';'license'='closed';'textLength'=8;'URI'='http://korap.ids-mannheim.de/instance/example';'pubDate'=2018-04-07", 'Fields');

my $index = Krawfish::Index->new;

ok($doc = $doc->identify($index->dict), 'Turn terms into term_ids');

is($doc->fields->to_string(1), "#1=#2;#3=#4;#5=#6(8);#7='http://korap.ids-mannheim.de/instance/example';#8=#9(2018-04-07)", 'Fields');

is($doc->stream->to_string(1), q!(0)<>[#10;11$1;13$3](1)< >[#15;16$3](2)<->[#17](3)< >[#18;19$4;20$4](4)< >[#23;24$5;13$8](5)< >[#25;26$6](6)< >[#15;27$8](7)<->[#28](8)<.>[##]!, 'Stream');

is($doc->to_string(1), q![#1=#2;#3=#4;#5=#6(8);#7='http://korap.ids-mannheim.de/instance/example';#8=#9(2018-04-07)](0)<>[#10;11$1;13$3](1)< >[#15;16$3](2)<->[#17](3)< >[#18;19$4;20$4](4)< >[#23;24$5;13$8](5)< >[#25;26$6](6)< >[#15;27$8](7)<->[#28](8)<.>[##]!, 'Stringification');

done_testing;
__END__
