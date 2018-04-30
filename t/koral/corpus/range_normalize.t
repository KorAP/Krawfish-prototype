use Test::More;
use Test::Krawfish;
use Krawfish::Util::Constants qw/:RANGE/;
use strict;
use warnings;

use_ok('Krawfish::Koral::Corpus::Builder');
use_ok('Test::Krawfish::DateRanges');

my $cb = Krawfish::Koral::Corpus::Builder->new;

my $dr;

# Merge dates to ranges
$dr = $cb->bool_and(
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


# Simple combination
$dr = $cb->bool_or(
  $cb->bool_and(
    $cb->date('pub')->geq('2001'),
    $cb->date('pub')->leq('2005')
  ),
  $cb->bool_and(
    $cb->date('pub')->geq('2007'),
    $cb->date('pub')->leq('2009')
  )
);
is($dr->to_string, '(pub>=2001&pub<=2005)|(pub>=2007&pub<=2009)', 'Stringification');
ok($dr = $dr->normalize, 'Normalize');
ok($dr = $dr->finalize, 'Finalize');

# This normalization may fail with "within" queries
is($dr->to_string,
   '(pub=2001[|pub=2001]|pub=2002[|pub=2002]|pub=2003[|pub=2003]|'.
     'pub=2004[|pub=2004]|pub=2005[|pub=2005]|pub=2007[|pub=2007]|pub=2008[|pub=2008]|pub=2009[|pub=2009])&[1]',
   'Normalization');



# Embedding combination
$dr = $cb->bool_or(
  $cb->bool_and(
    $cb->date('pub')->geq('2001'),
    $cb->date('pub')->leq('2005')
  ),
  $cb->bool_and(
    $cb->date('pub')->geq('2002-10-14'),
    $cb->date('pub')->leq('2003-11-09')
  )
);

is($dr->to_string, '(pub>=2001&pub<=2005)|(pub>=2002-10-14&pub<=2003-11-09)', 'Stringification');
ok($dr = $dr->normalize, 'Normalize');
ok($dr = $dr->finalize, 'Finalize');

# This normalization may fail with "within" queries
is($dr->to_string,
   '(pub=2001[|pub=2001]|pub=2002[|pub=2002]|pub=2003[|pub=2003]|pub=2004[|pub=2004]|pub=2005[|pub=2005])&[1]',
   'Normalization');



# >=2001 & <=2005 & >= 2002-10-14 & <= 2003-11-09
# Embedding combination
$dr = $cb->bool_and(
  $cb->date('pub')->geq('2001'),
  $cb->date('pub')->leq('2005'),
  $cb->date('pub')->geq('2002-10-14'),
  $cb->date('pub')->leq('2003-11-09')
);
is($dr->to_string, 'pub>=2001&pub>=2002-10-14&pub<=2003-11-09&pub<=2005',
   'Stringification');
ok($dr = $dr->normalize, 'Normalize');
ok($dr = $dr->finalize, 'Finalize');

# This normalization may fail with "within" queries
is($dr->to_string,
   '(pub=2002-10-14]|pub=2002-10-15]|pub=2002-10-16]|pub=2002-10-17]|pub=2002-10-18]|pub=2002-10-19]|pub=2002-10-20]|pub=2002-10-21]|pub=2002-10-22]|pub=2002-10-23]|pub=2002-10-24]|pub=2002-10-25]|pub=2002-10-26]|pub=2002-10-27]|pub=2002-10-28]|pub=2002-10-29]|pub=2002-10-30]|pub=2002-10-31]|pub=2002-10]|pub=2002-11[|pub=2002-11]|pub=2002-12[|pub=2002-12]|pub=2002]|pub=2003-01[|pub=2003-01]|pub=2003-02[|pub=2003-02]|pub=2003-03[|pub=2003-03]|pub=2003-04[|pub=2003-04]|pub=2003-05[|pub=2003-05]|pub=2003-06[|pub=2003-06]|pub=2003-07[|pub=2003-07]|pub=2003-08[|pub=2003-08]|pub=2003-09[|pub=2003-09]|pub=2003-10[|pub=2003-10]|pub=2003-11-01]|pub=2003-11-02]|pub=2003-11-03]|pub=2003-11-04]|pub=2003-11-05]|pub=2003-11-06]|pub=2003-11-07]|pub=2003-11-08]|pub=2003-11-09]|pub=2003-11]|pub=2003])&[1]',
   'Normalization');



diag 'Limit open ranges';
# like >= 2007 to [[2007--2100]], <= 2004 to [[1000--2004]]

# TODO:
#   - Respect inclusivity
#   - Introduce DateTerm Field
#     This will be identical to String,
#     but can be normalized more efficiently,
#     as 2007[|2007-10[ is -> 2007[ etc.

done_testing;
__END__
