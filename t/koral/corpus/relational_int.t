use Test::More;
use Test::Krawfish;
use strict;
use warnings;

use_ok('Krawfish::Koral::Corpus::Builder');

ok(my $cb = Krawfish::Koral::Corpus::Builder->new, 'Create CorpusBuilder');

my $tree;

# Get tree
$tree = $cb->bool_and(
  $cb->integer('age')->geq(14),
  $cb->integer('age')->geq(27)
);

# Simplify geq
ok($tree = $tree->normalize, 'Query normalization');
is($tree->to_string, 'age>=27', 'Resolve idempotence');

# Get tree
$tree = $cb->bool_or(
  $cb->integer('age')->geq(14),
  $cb->integer('age')->geq(27)
);

# Simplify geq
ok($tree = $tree->normalize, 'Query normalization');
is($tree->to_string, 'age>=14', 'Resolve idempotence');

# Get tree
$tree = $cb->bool_and(
  $cb->integer('age')->leq(14),
  $cb->integer('age')->leq(27)
);

# Simplify leq
ok($tree = $tree->normalize, 'Query normalization');
is($tree->to_string, 'age<=14', 'Resolve idempotence');

# Get tree
$tree = $cb->bool_or(
  $cb->integer('age')->leq(14),
  $cb->integer('age')->leq(27)
);

# Simplify leq
ok($tree = $tree->normalize, 'Query normalization');
is($tree->to_string, 'age<=27', 'Resolve idempotence');



# Get tree
$tree = $cb->bool_and(
  $cb->integer('age')->geq(14),
  $cb->integer('age')->leq(14)
);

# Simplify leq and geq
ok($tree = $tree->normalize, 'Query normalization');
is($tree->to_string, 'age=14', 'Resolve idempotence');


# Get tree
$tree = $cb->bool_or(
  $cb->integer('age')->geq(14),
  $cb->integer('age')->leq(14)
);


# Simplify leq and geq
ok($tree = $tree->normalize, 'Query normalization');
is($tree->to_string, '[1]', 'Resolve idempotence');


# Get tree
$tree = $cb->bool_and(
  $cb->integer('age')->eq(14),
  $cb->integer('age')->geq(14)
);

# Simplify eq & leq|geq
ok($tree = $tree->normalize, 'Query normalization');
is($tree->to_string, 'age=14', 'Resolve idempotence');


# Get tree
$tree = $cb->bool_or(
  $cb->integer('age')->eq(14),
  $cb->integer('age')->geq(14)
);

# Simplify eq | leq|geq
ok($tree = $tree->normalize, 'Query normalization');
is($tree->to_string, 'age>=14', 'Resolve idempotence');


###################
# Complex queries #
###################

# Get tree
$tree = $cb->bool_and(
  $cb->integer('age')->leq(14),
  $cb->integer('age')->geq(14),
  $cb->integer('age')->eq(12),
);


# Simplify eq & leq|geq
# TODO:
#   As integers do not support multiple values
#   (in opposite to strings, that may serve as keywords)
#   this should be rendered as [0]!
ok($tree = $tree->normalize, 'Query normalization');
is($tree->to_string, 'age=12&age=14', 'Resolve idempotence');

SKIP: {

  skip "> and < not yet supported", 2;
  # Get tree
  $tree = $cb->bool_and(
    $cb->integer('age')->ne(14),
    $cb->integer('age')->leq(14),
  );

  ok($tree = $tree->normalize, 'Query normalization');
  is($tree->to_string, 'age<14', 'Resolve idempotence');
};


# Get tree
$tree = $cb->bool_or(
  $cb->integer('age')->ne(14),
  $cb->integer('age')->leq(14),
);

ok($tree = $tree->normalize, 'Query normalization');
is($tree->to_string, '[1]', 'Resolve idempotence');


# Get tree
$tree = $cb->bool_and(
  $cb->integer('age')->ne(14),
  $cb->integer('age')->leq(14),
  $cb->integer('age')->geq(14),
);

ok($tree = $tree->normalize, 'Query normalization');
is($tree->to_string, '[0]', 'Resolve idempotence');


# Test athor!=14 & author<=14 & author>=14

done_testing;
__END__

