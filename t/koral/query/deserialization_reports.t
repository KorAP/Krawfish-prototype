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

ok(!($query->normalize), "Normalize!");

ok($query->has_error, 'Query has an error');

my $kq = $query->to_koral_query;

is($kq->{'@type'}, 'koral:token');
is($kq->{'wrap'}->{'@type'}, 'koral:token');
is($kq->{'errors'}->[0]->[1], 'Type no term or termGroup');


# term
ok($query = $qb->from_koral(
  {
    '@type' => 'koral:token',
    wrap => {
      '@type' => 'koral:term'
    }
  }
), 'Import token with wrapped term');

# Token is null, like in Der >alte{0}< Mann
is($query->to_string, '[-]', 'Stringification');

ok($query = $query->normalize, "Normalize!");
is($query->to_string, '[-]{0}', 'Stringification');

ok(!$query->finalize, "Finalize!");

$kq = $query->to_koral_query;

is($kq->{'@type'}, 'koral:token');
is($kq->{'wrap'}->{'@type'}, 'koral:term');
is($kq->{'errors'}->[0]->[1], 'Unable to search for null tokens');


done_testing;

__END__
