use Test::More;
use strict;
use warnings;
use Mojo::JSON qw/encode_json decode_json/;
use Mojo::File;
use Data::Dumper;

use_ok('Krawfish::Koral::Query::Builder');

ok(my $qb = Krawfish::Koral::Query::Builder->new, 'New importer');

# token
ok(my $query = $qb->from_koral(
  {
    '@type' => 'koral:token',
    wrap => {
      '@type' => 'koral:token'
    }
  }
), 'Import token with wrapped token');

is($query->to_string, '[!!!]', 'Stringification');

ok(!(my $new_query = $query->normalize), "Normalize!");

ok($query->has_error, 'Query has an error');

my $kq = $query->to_koral_query;

is($kq->{'@type'}, 'koral:token');
is($kq->{'wrap'}->{'@type'}, 'koral:token');
is($kq->{'errors'}->[0]->[1], 'Type no term or termGroup');



done_testing;

__END__
