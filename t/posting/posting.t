use Test::More;
use strict;
use warnings;

use_ok('Krawfish::Posting');
use_ok('Krawfish::Util::Bits');

my $posting = Krawfish::Posting->new(
  doc_id => 4,
  flags => 0b1000_0000_0000_0000
);

is($posting->to_string, '[4]', 'Stringification');

is(
  reverse(bitstring($posting->corpus_flags(0b0100_0000_0000_0000))),
  '0000000000000000',
  'Bitstring'
);

is(
  reverse(bitstring($posting->corpus_flags(0b1001_0000_0000_1000))),
  '1000000000000000',
  'Bitstring'
);

$posting = Krawfish::Posting->new(
  doc_id => 4,
  flags => 0b1100_0000_0000_0000
);

is($posting->to_string, '[4!1]', 'Stringification');


$posting = Krawfish::Posting->new(
  doc_id => 4,
  flags => 0b1100_1000_0000_0000
);

is($posting->to_string, '[4!1,4]', 'Stringification');


$posting = Krawfish::Posting->new(
  doc_id => 4,
  flags => 0b1100_1000_0000_1000
);

is($posting->to_string, '[4!1,4,12]', 'Stringification');

done_testing;
