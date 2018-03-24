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





diag 'Further complex relational tests with dates';

done_testing;
__END__

