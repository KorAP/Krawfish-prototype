use Test::More;
use Test::Krawfish;
use strict;
use warnings;

use_ok('Krawfish::Koral::Corpus::Builder');

ok(my $cb = Krawfish::Koral::Corpus::Builder->new, 'Create CorpusBuilder');

my $tree;

# Get tree
$tree = $cb->bool_and(
  $cb->date('pubDate')->geq('2014'),
  $cb->date('pubDate')->geq('2018')
);

# Simplify geq
ok($tree = $tree->normalize, 'Query normalization');
is($tree->to_string, 'pubDate>=2018', 'Resolve idempotence');

# Get tree
$tree = $cb->bool_and(
  $cb->date('pubDate')->geq('2014-12'),
  $cb->date('pubDate')->geq('2018')
);

# Simplify geq
ok($tree = $tree->normalize, 'Query normalization');
is($tree->to_string, 'pubDate>=2018', 'Resolve relation');


# Get tree
$tree = $cb->bool_and(
  $cb->date('pubDate')->geq('2014-12-04'),
  $cb->date('pubDate')->geq('2018')
);

# Simplify geq
ok($tree = $tree->normalize, 'Query normalization');
is($tree->to_string, 'pubDate>=2018', 'Resolve relation');


# Get tree
$tree = $cb->bool_and(
  $cb->date('pubDate')->geq('2014-12-04'),
  $cb->date('pubDate')->geq('2014-04')
);

# Simplify geq
ok($tree = $tree->normalize, 'Query normalization');
is($tree->to_string, 'pubDate>=2014-12-04', 'Resolve relation');


# Get tree
$tree = $cb->bool_or(
  $cb->date('pubDate')->geq('2014'),
  $cb->date('pubDate')->geq('2018')
);

# Simplify geq
ok($tree = $tree->normalize, 'Query normalization');
is($tree->to_string, 'pubDate>=2014', 'Resolve idempotence');


# Get tree
$tree = $cb->bool_or(
  $cb->date('pubDate')->geq('2014-12-04'),
  $cb->date('pubDate')->geq('2018')
);

# Simplify geq
ok($tree = $tree->normalize, 'Query normalization');
is($tree->to_string, 'pubDate>=2014-12-04', 'Resolve idempotence');


# Get tree
$tree = $cb->bool_or(
  $cb->date('pubDate')->geq('2014-12-04'),
  $cb->date('pubDate')->geq('2014-04')
);

# Simplify geq
ok($tree = $tree->normalize, 'Query normalization');
is($tree->to_string, 'pubDate>=2014-04', 'Resolve relation');


# Get tree
$tree = $cb->bool_or(
  $cb->date('pubDate')->leq('2014-12-14'),
  $cb->date('pubDate')->leq('2014-12-27')
);

# Simplify geq
ok($tree = $tree->normalize, 'Query normalization');
is($tree->to_string, 'pubDate<=2014-12-27', 'Resolve relation');

# Get tree
$tree = $cb->bool_and(
  $cb->date('pubDate')->geq('2014-04'),
  $cb->date('pubDate')->leq('2014-04')
);

# Simplify leq and geq
ok($tree = $tree->normalize, 'Query normalization');
is($tree->to_string, 'pubDate=2014-04', 'Resolve idempotence');
ok($tree = $tree->finalize, 'Query normalization');
is($tree->to_string, '(pubDate=2014-04[|pubDate=2014-04]|pubDate=2014])&[1]', 'Resolve idempotence');


# Get tree
$tree = $cb->bool_or(
  $cb->date('pubDate')->geq('2014-04'),
  $cb->date('pubDate')->leq('2014-04')
);

# Simplify leq and geq
ok($tree = $tree->normalize, 'Query normalization');
is($tree->to_string, '[1]', 'Resolve idempotence');


# Get tree
$tree = $cb->bool_and(
  $cb->date('pubDate')->eq('2014-04'),
  $cb->date('pubDate')->geq('2014-04')
);

# Simplify eq & leq|geq
ok($tree = $tree->normalize, 'Query normalization');
is($tree->to_string, 'pubDate=2014-04', 'Normalization');
ok($tree = $tree->finalize, 'Query finalization');
is($tree->to_string, '(pubDate=2014-04[|pubDate=2014-04]|pubDate=2014])&[1]', 'Normalization');

# Get tree
$tree = $cb->bool_or(
  $cb->date('pubDate')->eq('2014-04'),
  $cb->date('pubDate')->geq('2014-04-00')
);

# Simplify eq | leq|geq
ok($tree = $tree->normalize, 'Query normalization');
is($tree->to_string, 'pubDate>=2014-04', 'Stringification');
ok($tree = $tree->finalize, 'Query finalization');
my $norm = $tree->to_string;
like($norm, qr/^\(pubDate=2014-04\[\|pubDate=2014-04\]\|/, 'Resolve idempotence');
like($norm, qr/\|pubDate=2199\]\|pubDate=2200\[\|pubDate=2200\]\)&\[1\]$/, 'Resolve idempotence');



###################
# Complex queries #
###################

# Get tree
$tree = $cb->bool_and(
  $cb->date('pubDate')->leq('2014-12-04'),
  $cb->date('pubDate')->geq('2014-12-04'),
  $cb->date('pubDate')->eq('2014-04'),
);


# Simplify eq & leq|geq
# TODO: this may be simplified even more
ok($tree = $tree->normalize, 'Query normalization');
is($tree->to_string, 'pubDate=2014-04&pubDate=2014-12-04', 'Resolve idempotence');
ok($tree = $tree->finalize, 'Query finalization');
is($tree->to_string, '((pubDate=2014-04[|pubDate=2014-04]|pubDate=2014])&(pubDate=2014-12-04]|pubDate=2014-12]|pubDate=2014]))&[1]',
   'Resolve idempotence');

# Get tree
$tree = $cb->bool_or(
  $cb->date('pubDate')->ne('2014-04'),
  $cb->date('pubDate')->leq('2014-04'),
);

ok($tree = $tree->normalize, 'Query normalization');
is($tree->to_string, '[1]', 'Resolve idempotence');

# Get tree
$tree = $cb->bool_and(
  $cb->date('pubDate')->ne('2014-04'),
  $cb->date('pubDate')->leq('2014-04'),
  $cb->date('pubDate')->geq('2014-04'),
);

ok($tree = $tree->normalize, 'Query normalization');
is($tree->to_string, '[0]', 'Resolve idempotence');


ok(my $min = $cb->date('pubDate')->minimum, 'Create minimum date');
is($min->to_string, 'pubDate=1000-01-01', 'Minimum date');

ok(my $max = $cb->date('pubDate')->maximum, 'Create maximum date');
is($max->to_string, 'pubDate=2200-12-31', 'Minimum date');

is($cb->date('pubDate')->minimum->next_date->to_string, 'pubDate=1000-01-02',
   'Get next date');

# is($cb->date('pubDate')->maximum->next_date->to_string, 'pubDate=1000-01-02',
#    'Get next date');


# Check next date
is($cb->date('pubDate')->eq('2005')->next_date->to_string, 'pubDate=2006',
   'Get next date');

is($cb->date('pubDate')->eq('2005-10')->next_date->to_string, 'pubDate=2005-11',
   'Get next date');

is($cb->date('pubDate')->eq('2005-10-06')->next_date->to_string, 'pubDate=2005-10-07',
   'Get next date');

is($cb->date('pubDate')->eq('2005-10-31')->next_date->to_string, 'pubDate=2005-11-01',
   'Get next date');

is($cb->date('pubDate')->eq('2005-12')->next_date->to_string, 'pubDate=2006-01',
   'Get next date');

is($cb->date('pubDate')->eq('2005-12-31')->next_date->to_string, 'pubDate=2006-01-01',
   'Get next date');

# Check previous date
is($cb->date('pubDate')->eq('2005')->previous_date->to_string, 'pubDate=2004',
   'Get previous date');

is($cb->date('pubDate')->eq('2005-08')->previous_date->to_string, 'pubDate=2005-07',
   'Get previous date');

is($cb->date('pubDate')->eq('2005-08-07')->previous_date->to_string, 'pubDate=2005-08-06',
   'Get previous date');

is($cb->date('pubDate')->eq('2005-10-01')->previous_date->to_string, 'pubDate=2005-09-30',
   'Get previous date');

is($cb->date('pubDate')->eq('2005-09-01')->previous_date->to_string, 'pubDate=2005-08-31',
   'Get previous date');

is($cb->date('pubDate')->eq('2005-03-01')->previous_date->to_string, 'pubDate=2005-02-29',
   'Get previous date');

is($cb->date('pubDate')->eq('2005-01-01')->previous_date->to_string, 'pubDate=2004-12-31',
   'Get previous date');

is($cb->date('pubDate')->eq('2005-01')->previous_date->to_string, 'pubDate=2004-12',
   'Get previous date');


sub join_ranges {
  my ($range_a, $range_b) = @_;
  return $cb->date('date')->intersect(
    $range_a->[0],
    $range_a->[1]
  )->join_with(
    $cb->date('date')->intersect(
      $range_b->[0],
      $range_b->[1]
    )
  );
};



# Check joins (all 13 possible configurations)
# MATCHES
is(join_ranges(
  ['2007', '2011'],
  ['2007', '2011']
)->to_string, 'date&=[[2007--2011]]');

# ALIGNS_LEFT
is(join_ranges(
  ['2007', '2009'],
  ['2007', '2011']
)->to_string, 'date&=[[2007--2011]]');

# ALIGNS_LEFT REV
is(join_ranges(
  ['2007', '2011'],
  ['2007', '2009']
)->to_string, 'date&=[[2007--2011]]');

# PRECEDES_DIRECTLY
is(join_ranges(
  ['2007', '2009'],
  ['2009', '2012']
)->to_string, 'date&=[[2007--2012]]');

# PRECEDES_DIRECTLY REV
is(join_ranges(
  ['2009', '2012'],
  ['2007', '2009']
)->to_string, 'date&=[[2007--2012]]');

# ENDS_WITH
is(join_ranges(
  ['2007', '2017'],
  ['2009', '2017']
)->to_string, 'date&=[[2007--2017]]');

# ENDS_WITH REV
is(join_ranges(
  ['2009', '2017'],
  ['2007', '2017']
)->to_string, 'date&=[[2007--2017]]');

# OVERLAPS_LEFT
is(join_ranges(
  ['2007', '2009'],
  ['2008', '2011']
)->to_string, 'date&=[[2007--2011]]');

# OVERLAPS_LEFT REV
is(join_ranges(
  ['2008', '2011'],
  ['2007', '2009']
)->to_string, 'date&=[[2007--2011]]');

# IS_AROUND
is(join_ranges(
  ['2007', '2016'],
  ['2009', '2011']
)->to_string, 'date&=[[2007--2016]]');

# IS_AROUND REV
is(join_ranges(
  ['2009', '2011'],
  ['2007', '2016']
)->to_string, 'date&=[[2007--2016]]');

# !PRECEDES
ok(!join_ranges(
  ['2007', '2009'],
  ['2010', '2012']
), 'No precedes');

# !PRECEDES REV
ok(!join_ranges(
  ['2010', '2012'],
  ['2007', '2009']
), 'No precedes');


SKIP: {
  skip "> and < not yet supported", 2;
  # TODO: Deal with year==900
  # See relational_string.t
  # TODO:
  #   Limit maximum and minimum for next_date and previous_date
};


done_testing;
__END__

