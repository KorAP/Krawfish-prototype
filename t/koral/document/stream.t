use strict;
use warnings;
use Test::More;
use Test::Krawfish;

use_ok('Krawfish::Koral::Document::Stream');

ok(my $stream = Krawfish::Koral::Document::Stream->new);

my @array = (
  ['','Der'],
  [' ','alte'],
  [' ','Mann']
);

my $i = 0;
foreach (@array) {
  my $subtoken = Krawfish::Koral::Document::Subtoken->new(
    preceding => $_->[0],
    subterm => $_->[1]
  );
  $stream->subtoken($i++, $subtoken);
};

is(
  $stream->to_string,
  "(0)<>['Der'](1)< >['alte'](2)< >['Mann']"
);

my $kq = $stream->to_koral_fragment;

is($kq->{string}, 'Der alte Mann');


done_testing;

__END__
