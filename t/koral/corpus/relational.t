use Test::More;
use Test::Krawfish;
use strict;
use warnings;

use_ok('Krawfish::Koral::Corpus::Builder');

ok(my $cb = Krawfish::Koral::Corpus::Builder->new, 'Create CorpusBuilder');

my $tree;

# Get tree
$tree = $cb->bool_and(
  $cb->string('name')->geq('Peter'),
  $cb->string('name')->geq('Rolf')
);

# Simplify geq
ok($tree = $tree->normalize, 'Query normalization');
is($tree->to_string, 'name>=Rolf', 'Resolve idempotence');

# Get tree
$tree = $cb->bool_or(
  $cb->string('name')->geq('Peter'),
  $cb->string('name')->geq('Rolf')
);

# Simplify geq
ok($tree = $tree->normalize, 'Query normalization');
is($tree->to_string, 'name>=Peter', 'Resolve idempotence');


# Get tree
$tree = $cb->bool_and(
  $cb->string('name')->leq('Peter'),
  $cb->string('name')->leq('Rolf')
);

# Simplify leq
ok($tree = $tree->normalize, 'Query normalization');
is($tree->to_string, 'name<=Peter', 'Resolve idempotence');

# Get tree
$tree = $cb->bool_or(
  $cb->string('name')->leq('Peter'),
  $cb->string('name')->leq('Rolf')
);

# Simplify leq
ok($tree = $tree->normalize, 'Query normalization');
is($tree->to_string, 'name<=Rolf', 'Resolve idempotence');


# Get tree
$tree = $cb->bool_and(
  $cb->string('name')->geq('Peter'),
  $cb->string('name')->leq('Peter')
);

# Simplify leq and geq
ok($tree = $tree->normalize, 'Query normalization');
is($tree->to_string, 'name=Peter', 'Resolve idempotence');


# Get tree
$tree = $cb->bool_or(
  $cb->string('name')->geq('Peter'),
  $cb->string('name')->leq('Peter')
);

# Simplify leq and geq
ok($tree = $tree->normalize, 'Query normalization');
is($tree->to_string, '[1]', 'Resolve idempotence');


# Get tree
$tree = $cb->bool_and(
  $cb->string('name')->eq('Peter'),
  $cb->string('name')->geq('Peter')
);

# Simplify eq & leq|geq
ok($tree = $tree->normalize, 'Query normalization');
is($tree->to_string, 'name=Peter', 'Resolve idempotence');


# Get tree
$tree = $cb->bool_or(
  $cb->string('name')->eq('Peter'),
  $cb->string('name')->geq('Peter')
);

# Simplify eq | leq|geq
ok($tree = $tree->normalize, 'Query normalization');
is($tree->to_string, 'name>=Peter', 'Resolve idempotence');


###################
# Complex queries #
###################

# Get tree
$tree = $cb->bool_and(
  $cb->string('name')->leq('Peter'),
  $cb->string('name')->geq('Peter'),
  $cb->string('name')->eq('Michael'),
);


# Simplify eq & leq|geq
ok($tree = $tree->normalize, 'Query normalization');
is($tree->to_string, 'name=Michael&name=Peter', 'Resolve idempotence');

SKIP: {

  skip "> and < not yet supported", 2;
  # Get tree
  $tree = $cb->bool_and(
    $cb->string('name')->ne('Peter'),
    $cb->string('name')->leq('Peter'),
  );

  ok($tree = $tree->normalize, 'Query normalization');
  is($tree->to_string, 'name<Peter', 'Resolve idempotence');
};


# Get tree
$tree = $cb->bool_or(
  $cb->string('name')->ne('Peter'),
  $cb->string('name')->leq('Peter'),
);

ok($tree = $tree->normalize, 'Query normalization');
is($tree->to_string, '[1]', 'Resolve idempotence');


diag 'Mix relations with boolean operations';

# Test athor!=Peter & author<=Peter & author>=Peter

done_testing;
__END__

