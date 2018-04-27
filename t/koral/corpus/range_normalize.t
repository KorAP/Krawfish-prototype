use Test::More;
use Test::Krawfish;
use Krawfish::Util::Constants qw/:RANGE/;
use strict;
use warnings;

use_ok('Krawfish::Koral::Corpus::Builder');
use_ok('Test::Krawfish::DateRanges');

my $cb = Krawfish::Koral::Corpus::Builder->new;

# Merge dates to ranges
my $dr = $cb->bool_and(
  $cb->date('pub')->geq('2015'),
  $cb->date('pub')->leq('2018')
);
is($dr->to_string, 'pub>=2015&pub<=2018', 'Stringification');
ok($dr = $dr->normalize, 'Normalize');
is($dr->to_string,
   'pub=2015[|pub=2015]|pub=2016[|pub=2016]|pub=2017[|pub=2017]|pub=2018[|pub=2018]',
 'Normalization');


# Create negative normalization
$dr = $cb->bool_and(
  $cb->date('pub')->leq('2015'),
  $cb->date('pub')->geq('2018')
);
is($dr->to_string, 'pub<=2015&pub>=2018', 'Stringification');
ok($dr = $dr->normalize, 'Normalize');
ok($dr = $dr->finalize, 'Finalize');
is($dr->to_string,
   '([1]&!(pub=2015[|pub=2015]|pub=2018[|pub=2018]))',
 'Normalization');


diag 'Merge ranges in Util::Ranges';

# TODO:
#   - Limit open ranges like >= 2007 to [[2007--2100]], <= 2004 to [[1000--2004]]
#   - Respect inclusivity

done_testing;
__END__
