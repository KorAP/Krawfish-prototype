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

# Test day-to-day-in-month
is($dr_index->add_range(
  4 => '2005-10-14' . RANGE_SEP . '2005-10-17'
), 6);

# Test day-to-month-in-year
is($dr_index->add_range(
  5 => '2005-10-27' . RANGE_SEP . '2005-12'
), 9);

# Test day-to-year
is($dr_index->add_range(
  6 => '2005-10-27' . RANGE_SEP . '2006'
), 8);

# Test day-to-month
is($dr_index->add_range(
  7 => '2005-10-27' . RANGE_SEP . '2007-04'
), 13);

# Test day-to-day
is($dr_index->add_range(
  8 => '2005-10-27' . RANGE_SEP . '2007-04-04'
), 17);

# Test day-to-day-in-year
is($dr_index->add_range(
  9 => '2005-10-27' . RANGE_SEP . '2005-11-04'
), 12);



# NORMALIZATION CASES ##
# Adding ranges with a doc_id of 0: ignore!

# Test day-to-year-in-year
is($dr_index->add_range(
  0 => '2005-10-14' . RANGE_SEP . '2005'
), 1, 'Normalize day-to-year-in-year');

# Test day-to-month-in-month
is($dr_index->add_range(
  0 => '2005-10-14' . RANGE_SEP . '2005-10'
), 2, 'Normalize day-to-month-in-month');

# Test day-to-day-in-day
is($dr_index->add_range(
  0 => '2005-10-14' . RANGE_SEP . '2005-10-14'
), 3, 'Normalize day-to-day-in-day');

# ---

# Test month-to-year-in-year
is($dr_index->add_range(
  0 => '2005-10' . RANGE_SEP . '2005'
), 1, 'Normalize month-to-year-in-year');

# Test month-to-month-in-month
is($dr_index->add_range(
  0 => '2005-10' . RANGE_SEP . '2005-10'
), 2, 'Normalize month-to-month-in-month');

# Test month-to-day-in-month
is($dr_index->add_range(
  0 => '2005-10' . RANGE_SEP . '2005-10-14'
), 2, 'Normalize month-to-day-in-month');

# ---

# Test year-to-year-in-year
is($dr_index->add_range(
  0 => '2005' . RANGE_SEP . '2005'
), 1, 'Normalize year-to-year-in-year');

# Test year-to-month-in-year
is($dr_index->add_range(
  0 => '2005' . RANGE_SEP . '2005-10'
), 1, 'Normalize year-to-month-in-year');

# Test year-to-day-in-year
is($dr_index->add_range(
  0 => '2005' . RANGE_SEP . '2005-10-14'
), 1, 'Normalize year-to-day-in-year');






done_testing;
__END__
