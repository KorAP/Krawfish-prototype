use Test::More;
use Test::Krawfish;
use Krawfish::Util::Constants qw/:RANGE/;
use strict;
use warnings;

use_ok('Krawfish::Koral::Corpus::Builder');
use_ok('Test::Krawfish::DateRanges');

my $r = RANGE_SEP;

my $cb = Krawfish::Koral::Corpus::Builder->new;

my $date = $cb->date('pubDate')->intersect('2015-11-14');

is($date->to_string, 'pubDate&=2015-11-14');

# Get all terms to request relevant for intersection
my @terms = $date->to_term_queries;
is($terms[0]->to_string, 'pubDate=2015-11-14' . RANGE_ALL_POST);
is($terms[1]->to_string, 'pubDate=2015-11' . RANGE_ALL_POST);
is($terms[2]->to_string, 'pubDate=2015' . RANGE_ALL_POST);

# Month granularity
$date = $cb->date('pubDate')->intersect('2015-11');
is($date->to_string, 'pubDate&=2015-11');

# Get all terms to request relevant for intersection
@terms = $date->to_term_queries;
is($terms[0]->to_string, 'pubDate=2015-11' . RANGE_PART_POST);
is($terms[1]->to_string, 'pubDate=2015-11' . RANGE_ALL_POST);
is($terms[2]->to_string, 'pubDate=2015' . RANGE_ALL_POST);
ok(!$terms[3], 'No more terms');

# year granularity
$date = $cb->date('pubDate')->intersect('2015');
is($date->to_string, 'pubDate&=2015');

# Get all terms to request relevant for intersection
@terms = $date->to_term_queries;
is($terms[0]->to_string, 'pubDate=2015' . RANGE_PART_POST);
is($terms[1]->to_string, 'pubDate=2015' . RANGE_ALL_POST);
ok(!$terms[2], 'No more terms');

# Create range query with two dates
my $range = $cb->date('pubDate')->intersect('2015', '2017');
is($range->to_string, 'pubDate&=[[2015--2017]]');

@terms = sort {
  $a->to_sort_string cmp $b->to_sort_string
} $range->to_term_queries;
is($terms[0]->to_string, 'pubDate=2015[');
is($terms[1]->to_string, 'pubDate=2015]');
is($terms[2]->to_string, 'pubDate=2016[');
is($terms[3]->to_string, 'pubDate=2016]');
is($terms[4]->to_string, 'pubDate=2017[');
is($terms[5]->to_string, 'pubDate=2017]');

my $dr = Test::Krawfish::DateRanges->new;

is($dr->add_range(1 => '2005'), 1, 'Add 2005');
is($dr->add_range(2 => '2005-10'), 2, 'Add 2005-10');
is($dr->add_range(3 => '2005-10-14'), 3, 'Add 2005-10-14');

is_deeply($dr->query('2005-10-09'), [1,2], 'Check simple range query');
is_deeply($dr->query('2005-10'), [1,2,3], 'Check simple range query');
is_deeply($dr->query('2005-10-14'), [1,2,3], 'Check simple range query');
is_deeply($dr->query('2005'), [1,2,3], 'Check simple range query');
is_deeply($dr->query('2005-11'), [1], 'Check simple range query');

# Systematically test following the following range constellations:
#   'd' means 'day'
#   'm' means 'month'
#   'y' means 'year'
#   'd2m' means, the first date of the range has a day granularity,
#   the last date has month granularity, and the span years
#   (i.e. have nothing in common).
#   'in-x' means, the ranges share a common date on granularity,
#   e.g. d2m-in-year means the first date has day granularity, the last date
#   has month granularity, and they span the same year, like
#   2005-10-27--2005-11.
#   A leading exclamation mark means, the range can be normalized, so one
#   of the dates in the range is obsolete, as one date subordinates the other.

# d2d
# d2m
# d2y
#
# !d2d-in-day
# d2d-in-month
# d2d-in-year
# !d2m-in-month
# d2m-in-year
# !d2y-in-year
#
# m2d
# m2m
# m2y
#
# !m2d-in-month
# m2d-in-year
# !m2m-in-month
# m2m-in-year
# !m2y-in-year
#
# y2d
# y2m
# y2y
#
# !y2d-in-year
# !y2m-in-year
# !y2y-in-year


# Test day-to-day
is($dr->add_range(
  0 => "2005-10-27${r}2007-04-04"
), 19);

# Test day-to-month
is($dr->add_range(
  0 => "2005-10-27${r}2007-04"
), 15);

# Test day-to-year
is($dr->add_range(
  0 => "2005-10-27${r}2006"
), 10);

# Normalize day-to-day-in-day
is($dr->add_range(
  0 => "2005-10-14${r}2005-10-14"
), 3, 'Normalize day-to-day-in-day');

# Test day-to-month-in-year
is($dr->add_range(
  0 => "2005-10-27${r}2005-12"
), 9);

# Test day-to-day-in-year
is($dr->add_range(
  0 => "2005-10-27${r}2005-11-04"
), 12);

# Normalize day-to-month-in-month
is($dr->add_range(
  0 => "2005-10-14${r}2005-10"
), 2, 'Normalize day-to-month-in-month');

# Test day-to-month-in-year
is($dr->add_range(
  0 => "2005-10-27${r}2005-11"
), 8, 'Test day-to-month-in-year');

# Normalize day-to-year-in-year
is($dr->add_range(
  0 => "2005-10-14${r}2005"
), 1, 'Normalize day-to-year-in-year');

# Test month-to-day
is($dr->add_range(
  0 => "2005-10${r}2006-02-04"
), 11, 'Test month-to-day');

# Test month-to-month
is($dr->add_range(
  0 => "2005-10${r}2006-11"
), 16, 'Test month-to-month');

# Test month-to-year
is($dr->add_range(
  0 => "2005-10${r}2008"
), 7, 'Test month-to-year');

# Normalize month-to-day-in-month
is($dr->add_range(
  0 => "2005-10${r}2005-10-14"
), 2, 'Normalize month-to-day-in-month');

# Test month-to-day-in-year
is($dr->add_range(
  0 => "2005-10${r}2005-11-02"
), 5, 'Test month-to-day-in-year');

# Normalize month-to-month-in-month
is($dr->add_range(
  0 => "2005-10${r}2005-10"
), 2, 'Normalize month-to-month-in-month');

# Test month-to-month-in-year
is($dr->add_range(
  0 => "2005-10${r}2005-12"
), 4, 'Test month-to-month-in-year');

# Normalize month-to-year-in-year
is($dr->add_range(
  0 => "2005-10${r}2005"
), 1, 'Normalize month-to-year-in-year');

# Test year-to-day
is($dr->add_range(
  0 => "2005${r}2006-02-02"
), 6, 'Test year-to-day');

# Test year-to-month
is($dr->add_range(
  0 => "2005${r}2006-02"
), 4, 'Test year-to-day');

# Test year-to-year
is($dr->add_range(
  0 => "2005${r}2008"
), 4, 'Test year-to-year');

# Test year-to-day-in-year
is($dr->add_range(
  0 => "2005${r}2005-10-14"
), 1, 'Normalize year-to-day-in-year');

# Test year-to-month-in-year
is($dr->add_range(
  0 => "2005${r}2005-10"
), 1, 'Normalize year-to-month-in-year');

# Test year-to-year-in-year
is($dr->add_range(
  0 => "2005${r}2005"
), 1, 'Normalize year-to-year-in-year');


ok($dr->clear, 'Clear index');
# Queries


# Check simple ranges with single date queries
ok($dr->add_range(1 => "2005${r}2007"), 'Add y2y');
ok($dr->add_range(2 => "2005-02${r}2007-10"), 'Add m2m');
ok($dr->add_range(3 => "2005-02-07${r}2007-10-14"), 'Add d2d');

is_deeply($dr->query('2005-02-06'), [1,2], 'Query before 3');
is_deeply($dr->query('2005-02-09'), [1,2,3], 'Query in 3a');
is_deeply($dr->query('2006-04-12'), [1,2,3], 'Query in 3b');
is_deeply($dr->query('2007-09-13'), [1,2,3], 'Query in 3c');
is_deeply($dr->query('2007-10-17'), [1,2], 'Query after 3');

is_deeply($dr->query('2005-01-04'), [1], 'Query before 2');
is_deeply($dr->query('2005-02-04'), [1,2], 'Query in 2a');
is_deeply($dr->query('2006-02-04'), [1,2,3], 'Query in 2b');
is_deeply($dr->query('2007-10-31'), [1,2], 'Query in 2c');
is_deeply($dr->query('2007-11-01'), [1], 'Query after 2');

is_deeply($dr->query('2004-12-31'), [], 'Query before 1');
is_deeply($dr->query('2008-01-01'), [], 'Query after 1');

# 3 overlapping timeranges
ok($dr->add_range(4 => "2001-04-05${r}2002-02-07"), 'Add d2d');
ok($dr->add_range(5 => "2002-01-02${r}2003-10-08"), 'Add d2d');
ok($dr->add_range(6 => "2002-09-31${r}2003-11-05"), 'Add d2d');

is_deeply($dr->query('2001-02'), [], 'Query before 4');
is_deeply($dr->query('2001-09'), [4], 'Query in 4');
is_deeply($dr->query('2002-02'), [4,5], 'Query in 4 and 5');
is_deeply($dr->query('2002-05'), [5], 'Query in 5');
is_deeply($dr->query('2002-10'), [5,6], 'Query in 5 and 6');
is_deeply($dr->query('2003-10'), [5,6], 'Query in 5 and 6');
is_deeply($dr->query('2003-11'), [6], 'Query in 6');
is_deeply($dr->query('2003-12'), [], 'Query after 6');

ok($dr->add_range(7 => "2005-02-10"), 'Add day');
ok($dr->add_range(8 => "2007-11-04"), 'Add day');
ok($dr->add_range(9 => "2007-12-04"), 'Add day');

# 1 => "2005${r}2007"
# 2 => "2005-02${r}2007-10"
# 3 => "2005-02-07${r}2007-10-14"
# 4 => "2001-04-05${r}2002-02-07"
# 5 => "2002-01-02${r}2003-10-08"
# 6 => "2002-09-31${r}2003-11-05"
# 7 => "2005-02-10"
# 8 => "2007-11-04"
# 9 => "2007-12-04"

# TODO:
#   Check daterange queries with the same systematic as before.

is_deeply($dr->query('2005-02-02', '2006-01-02'), [1,2,3,7], 'Query d2d');
is_deeply($dr->query('2007-10-18', '2008-12-03'), [1,2,8,9], 'Query d2d');
is_deeply($dr->query('2007-11-02', '2008-12-03'), [1,8,9], 'Query d2d');

is_deeply($dr->query('2002-02-09', '2003-11'), [5,6], 'Query d2m');

is_deeply($dr->query('2002-02-06', '2003'), [4,5,6], 'Query d2y');
is_deeply($dr->query('2002-02-09', '2003'), [5,6], 'Query d2y');

is_deeply($dr->query('2007-11-04', '2007-11-04'), [1,8], 'Normalize d2d-in-day');

is_deeply($dr->query('2007-10-02', '2007-10-05'), [1,2,3], 'Query d2d-in-month');
is_deeply($dr->query('2007-09-02', '2007-09-05'), [1,2,3], 'Query d2d-in-month');
is_deeply($dr->query('2005-02-12', '2005-02-14'), [1,2,3], 'Query d2d-in-month');
is_deeply($dr->query('2005-02-08', '2005-02-11'), [1,2,3,7], 'Query d2d-in-month');

is_deeply($dr->query('2002-02-09', '2002-11-03'), [5,6], 'Query d2d-in-year');
is_deeply($dr->query('2007-10-28', '2007-11-01'), [1,2], 'Query d2d-in-year');

is_deeply($dr->query('2007-11-28', '2007-11'), [1,8], 'Normalize d2m-in-month');

is_deeply($dr->query('2007-10-28', '2007-12'), [1,2,8,9], 'Query d2m-in-year');

is_deeply($dr->query('2007-10-28', '2007'), [1,2,3,8,9], 'Normalize d2m-in-year');

is_deeply($dr->query('2002-03', '2003-01-12'), [5,6], 'Query m2d');

is_deeply($dr->query('2001-02', '2005-02'), [1,2,3,4,5,6,7], 'Query m2m');
is_deeply($dr->query('2003-11', '2005-02'), [1,2,3,6,7], 'Query m2m');
is_deeply($dr->query('2003-11', '2005-01'), [1,6], 'Query m2m');

is_deeply($dr->query('2003-11', '2005'), [1,2,3,6,7], 'Query m2y');

is_deeply($dr->query('2003-03', '2003-03-28'), [5,6], 'Normalize m2d-in-month');

is_deeply($dr->query('2003-03', '2003-04-28'), [5,6], 'Query m2d');

is_deeply($dr->query('2007-11', '2007-11'), [1,8], 'Normalize m2m-in-month');

is_deeply($dr->query('2007-10', '2007-12'), [1,2,3,8,9], 'Query m2m-in-year');

is_deeply($dr->query('2002-11', '2002'), [4,5,6], 'Normalize m2y-in-year');

is_deeply($dr->query('2002', '2003-10-10'), [4,5,6], 'Query y2d');

is_deeply($dr->query('2002', '2003-10'), [4,5,6], 'Query y2m');

is_deeply($dr->query('2001', '2002'), [4,5,6], 'Query y2y');
is_deeply($dr->query('2002', '2003'), [4,5,6], 'Query y2y');
is_deeply($dr->query('2003', '2005'), [1,2,3,5,6,7], 'Query y2y');

is_deeply($dr->query('2007', '2007-10-28'), [1,2,3,8,9], 'Normalize y2d-in-year');
is_deeply($dr->query('2002', '2002-11-30'), [4,5,6], 'Normalize y2d-in-year');

is_deeply($dr->query('2007', '2007-11'), [1,2,3,8,9], 'Normalize y2m-in-year');

is_deeply($dr->query('2007', '2007'), [1,2,3,8,9], 'Normalize y2y-in-year');
is_deeply($dr->query('2001', '2001'), [4], 'Normalize y2y-in-year');


# Normalize calendaric implicite information
# [[2007-01-01--2007-01-31]] -> 2007-01
$range = $cb->date('pubDate')->intersect(
  '2007-01-01', '2007-01-31'
);
is($range->to_string, 'pubDate&=[[2007-01-01--2007-01-31]]');
ok($range = $range->normalize, 'Normalization');
is($range->to_string, 'pubDate=2007-01[|pubDate=2007-01]|pubDate=2007]');

# [[2007-01-01--2007-02-31]] -> [[2007-01--2007-02]]
$range = $cb->date('pubDate')->intersect(
  '2007-01-01', '2007-02-31'
);
is($range->to_string, 'pubDate&=[[2007-01-01--2007-02-31]]');
ok($range = $range->normalize, 'Normalization');
is($range->to_string, 'pubDate=2007-01[|pubDate=2007-01]|pubDate=2007-02[|pubDate=2007-02]|pubDate=2007]');


# [[2007-01-01--2008-02-31]] -> [[2007-01--2008-02]]
$range = $cb->date('pubDate')->intersect(
  '2007-11-01', '2008-02-31'
);
is($range->to_string, 'pubDate&=[[2007-11-01--2008-02-31]]');
ok($range = $range->normalize, 'Normalization');
is($range->to_string, 'pubDate=2007-11[|pubDate=2007-11]|pubDate=2007-12[|pubDate=2007-12]|pubDate=2007]|pubDate=2008-01[|pubDate=2008-01]|pubDate=2008-02[|pubDate=2008-02]|pubDate=2008]');


# [[2007-01-01--2008-02-31]] -> [[2007--2008-02]]
$range = $cb->date('pubDate')->intersect(
  '2007-01-01', '2008-02-31'
);
is($range->to_string, 'pubDate&=[[2007-01-01--2008-02-31]]');
ok($range = $range->normalize, 'Normalization');
is($range->to_string, 'pubDate=2007[|pubDate=2007]|pubDate=2008-01[|pubDate=2008-01]|pubDate=2008-02[|pubDate=2008-02]|pubDate=2008]');


# [[2007-01-01--2007-12-31]] -> 2007
$range = $cb->date('pubDate')->intersect(
  '2007-01-01', '2007-12-31'
);
is($range->to_string, 'pubDate&=[[2007-01-01--2007-12-31]]');
ok($range = $range->normalize, 'Normalization');
is($range->to_string, 'pubDate=2007[|pubDate=2007]');

# [[2007-01-01--2009-12-31]] -> 2009
$range = $cb->date('pubDate')->intersect(
  '2007-01-01', '2009-12-31'
);
is($range->to_string, 'pubDate&=[[2007-01-01--2009-12-31]]');
ok($range = $range->normalize, 'Normalization');
is($range->to_string, 'pubDate=2007[|pubDate=2007]|pubDate=2008[|pubDate=2008]|pubDate=2009[|pubDate=2009]');


# Calendaric normalization of index fields
is($dr->add_range(
  0 => "2005-01-01${r}2008-12-31" # 2005--2008
), 4, 'Test month-to-year');

is($dr->add_range(
  0 => "2005-01-01${r}2005-03-04" # 2005-01--2005-03-04
), 8, 'Test month-to-year');

is($dr->add_range(
  0 => "2005-02-28${r}2005-03-31" # 2005-02-28--2005-03
), 7, 'Test month-to-year');

is($dr->add_range(
  0 => "2005-02-28${r}2005-12-31" # 2005-02-28--2005-12
), 16, 'Test month-to-year');



# Order dates in range
$date = $cb->date('pubDate')->intersect('2015-11','2005-02-31');
is($date->to_string, 'pubDate&=[[2005-02-31--2015-11]]');

is($dr->add_range(
  0 => "2005-12-31${r}2005-02-28" # 2005-02-28--2005-12
), 16, 'Test month-to-year with reverted data');

$date = $cb->date('pubDate')->intersect('2015-02','2014-11-01');
is($date->to_string, 'pubDate&=[[2014-11-01--2015-02]]');
ok($date = $date->normalize, 'Normalize');
is($date->to_string,
   'pubDate=2014-11[|pubDate=2014-11]|pubDate=2014-12[|pubDate=2014-12]|pubDate=2014]|pubDate=2015-01[|pubDate=2015-01]|pubDate=2015-02[|pubDate=2015-02]|pubDate=2015]');


# Order dates in range
$date = $cb->date('pubDate')->intersect('2015-11');
is($date->to_string, 'pubDate&=2015-11');
ok($date = $date->normalize, 'Normalize');
is($date->to_string,
   'pubDate=2015-11[|pubDate=2015-11]|pubDate=2015]');


done_testing;
__END__
