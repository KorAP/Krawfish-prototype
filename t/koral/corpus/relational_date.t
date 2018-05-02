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
is($tree->to_string, 'pubDate=2014-04', 'Resolve idempotence');


# Get tree
$tree = $cb->bool_or(
  $cb->date('pubDate')->eq('2014-04'),
  $cb->date('pubDate')->geq('2014-04-00')
);

# Simplify eq | leq|geq
ok($tree = $tree->normalize, 'Query normalization');
is($tree->to_string, 'pubDate>=2014-04', 'Resolve idempotence');


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
ok($tree = $tree->normalize, 'Query normalization');
is($tree->to_string, 'pubDate=2014-04&pubDate=2014-12-04',
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


SKIP: {
  skip "> and < not yet supported", 2;
  # TODO: Deal with year==900
  # See relational_string.t
  # TODO:
  #   Limit maximum and minimum for next_date and previous_date
};


done_testing;
__END__

