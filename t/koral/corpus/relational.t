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



diag 'Test more relations and mix with boolean operations';

# Test athor!=Peter & author<=Peter & author>=Peter

done_testing;
__END__

