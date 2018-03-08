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


# Simplify ge
ok($tree = $tree->normalize, 'Query normalization');
is($tree->to_string, 'name>=Rolf', 'Resolve idempotence');

diag 'Test more relations and mix with boolean operations';

done_testing;
__END__
