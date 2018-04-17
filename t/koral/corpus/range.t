use Test::More;
use Test::Krawfish;
use Krawfish::Util::Constants qw/:RANGE/;
use strict;
use warnings;

use_ok('Krawfish::Koral::Corpus::Builder');
use_ok('Test::Krawfish::DateRanges');

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

@terms = $range->to_term_queries;
is($terms[0]->to_string, 'pubDate=2015[');
is($terms[1]->to_string, 'pubDate=2015]');
is($terms[2]->to_string, 'pubDate=2016[');
is($terms[3]->to_string, 'pubDate=2016]');
is($terms[4]->to_string, 'pubDate=2017[');
is($terms[5]->to_string, 'pubDate=2017]');

my $dr_index = Test::Krawfish::DateRanges->new;

is($dr_index->add_range(1 => '2005'), 1, 'Add 2005');
is($dr_index->add_range(2 => '2005-10'), 2, 'Add 2005-10');
is($dr_index->add_range(3 => '2005-10-14'), 3, 'Add 2005-10-14');

is_deeply($dr_index->query('2005-10-09'), [1,2], 'Check simple range query');
is_deeply($dr_index->query('2005-10'), [1,2,3], 'Check simple range query');
is_deeply($dr_index->query('2005-10-14'), [1,2,3], 'Check simple range query');
is_deeply($dr_index->query('2005'), [1,2,3], 'Check simple range query');
is_deeply($dr_index->query('2005-11'), [1], 'Check simple range query');

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
is($dr_index->add_range(
  0 => '2005-10-27' . RANGE_SEP . '2007-04-04'
), 19);

# Test day-to-month
is($dr_index->add_range(
  0 => '2005-10-27' . RANGE_SEP . '2007-04'
), 15);

# Test day-to-year
is($dr_index->add_range(
  0 => '2005-10-27' . RANGE_SEP . '2006'
), 10);

# Normalize day-to-day-in-day
is($dr_index->add_range(
  0 => '2005-10-14' . RANGE_SEP . '2005-10-14'
), 3, 'Normalize day-to-day-in-day');

# Test day-to-month-in-year
is($dr_index->add_range(
  0 => '2005-10-27' . RANGE_SEP . '2005-12'
), 9);

# Test day-to-day-in-year
is($dr_index->add_range(
  0 => '2005-10-27' . RANGE_SEP . '2005-11-04'
), 12);

# Normalize day-to-month-in-month
is($dr_index->add_range(
  0 => '2005-10-14' . RANGE_SEP . '2005-10'
), 2, 'Normalize day-to-month-in-month');

# Test day-to-month-in-year
is($dr_index->add_range(
  0 => '2005-10-27' . RANGE_SEP . '2005-11'
), 8, 'Test day-to-month-in-year');

# Normalize day-to-year-in-year
is($dr_index->add_range(
  0 => '2005-10-14' . RANGE_SEP . '2005'
), 1, 'Normalize day-to-year-in-year');

# Test month-to-day
is($dr_index->add_range(
  0 => '2005-10' . RANGE_SEP . '2006-02-04'
), 11, 'Test month-to-day');

# Test month-to-month
is($dr_index->add_range(
  0 => '2005-10' . RANGE_SEP . '2006-11'
), 16, 'Test month-to-month');

# Test month-to-year
is($dr_index->add_range(
  0 => '2005-10' . RANGE_SEP . '2008'
), 7, 'Test month-to-year');

# Normalize month-to-day-in-month
is($dr_index->add_range(
  0 => '2005-10' . RANGE_SEP . '2005-10-14'
), 2, 'Normalize month-to-day-in-month');

# Test month-to-day-in-year
is($dr_index->add_range(
  0 => '2005-10' . RANGE_SEP . '2005-11-02'
), 5, 'Test month-to-day-in-year');

# Normalize month-to-month-in-month
is($dr_index->add_range(
  0 => '2005-10' . RANGE_SEP . '2005-10'
), 2, 'Normalize month-to-month-in-month');

# Test month-to-month-in-year
is($dr_index->add_range(
  0 => '2005-10' . RANGE_SEP . '2005-12'
), 4, 'Test month-to-month-in-year');

# Normalize month-to-year-in-year
is($dr_index->add_range(
  0 => '2005-10' . RANGE_SEP . '2005'
), 1, 'Normalize month-to-year-in-year');

# Test year-to-day
is($dr_index->add_range(
  0 => '2005' . RANGE_SEP . '2006-02-02'
), 6, 'Test year-to-day');

# Test year-to-month
is($dr_index->add_range(
  0 => '2005' . RANGE_SEP . '2006-02'
), 4, 'Test year-to-day');

# Test year-to-year
is($dr_index->add_range(
  0 => '2005' . RANGE_SEP . '2008'
), 4, 'Test year-to-year');

# Test year-to-day-in-year
is($dr_index->add_range(
  0 => '2005' . RANGE_SEP . '2005-10-14'
), 1, 'Normalize year-to-day-in-year');

# Test year-to-month-in-year
is($dr_index->add_range(
  0 => '2005' . RANGE_SEP . '2005-10'
), 1, 'Normalize year-to-month-in-year');

# Test year-to-year-in-year
is($dr_index->add_range(
  0 => '2005' . RANGE_SEP . '2005'
), 1, 'Normalize year-to-year-in-year');


# TODO:
# normalize 2007-01-01--2008-12-31
# -> 2007-2008
diag 'Normalize implicite month and year spans';

diag 'Test queries';

done_testing;
__END__
