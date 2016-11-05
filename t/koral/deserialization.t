use Test::More;
use strict;
use warnings;
use Mojo::JSON qw/encode_json decode_json/;
use Mojo::Util qw/slurp/;
use Data::Dumper;

use_ok('Krawfish::Koral');

# deserialize import document
my $doc_1 = slurp('t/data/doc1.jsonld');
my $koral = Krawfish::Koral->new(decode_json($doc_1));

done_testing;

__END__
