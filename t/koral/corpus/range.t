use Test::More;
use Test::Krawfish;
use Krawfish::Util::Constants qw/:RANGE/;
use strict;
use warnings;

use_ok('Krawfish::Koral::Corpus::Builder');

my $cb = Krawfish::Koral::Corpus::Builder->new;

my $date = $cb->date('pubDate')->intersect('2015-11-14');

is($date->to_string, 'pubDate&=2015-11-14');

# Get all terms to request relevant for intersection
my @terms = $date->to_intersecting_terms;
is($terms[0]->to_string, 'pubDate=2015-11-14' . RANGE_ALL_POST);
is($terms[1]->to_string, 'pubDate=2015-11' . RANGE_ALL_POST);
is($terms[2]->to_string, 'pubDate=2015' . RANGE_ALL_POST);


# Month granularity
$date = $cb->date('pubDate')->intersect('2015-11');
is($date->to_string, 'pubDate&=2015-11');

# Get all terms to request relevant for intersection
@terms = $date->to_intersecting_terms;
is($terms[0]->to_string, 'pubDate=2015-11' . RANGE_ALL_POST);
is($terms[1]->to_string, 'pubDate=2015' . RANGE_ALL_POST);


# year granularity
$date = $cb->date('pubDate')->intersect('2015');
is($date->to_string, 'pubDate&=2015');

# Get all terms to request relevant for intersection
@terms = $date->to_intersecting_terms;
is($terms[0]->to_string, 'pubDate=2015' . RANGE_ALL_POST);


# Create range query with two dates
my $range = $cb->date('pubDate')->intersect('2015-11', '2015-13-02');
is($range->to_string, 'pubDate&=[[2015-11--2015-13-02]]');



#ok($range = $range->normalize, 'Normalize');

done_testing;
__END__
