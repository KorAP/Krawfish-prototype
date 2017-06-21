use Test::More;
use strict;
use warnings;
use Data::Dumper;

use_ok('Krawfish::Koral::Query::Builder');
# use_ok('Krawfish::Index');
# my $index = Krawfish::Index->new;

my $qb = Krawfish::Koral::Query::Builder->new;


# [a]
my $seq = $qb->seq(
  $qb->token('a')
);

is($seq->to_string, '[a]', 'Stringification');
ok($seq = $seq->normalize, 'Normalization');
is($seq->to_string, 'a', 'Stringification');
ok($seq = $seq->finalize, 'Normalization');
is($seq->to_string, 'a', 'Stringification');

# [a][b]
$seq = $qb->seq(
  $qb->token('a'),
  $qb->token('b')
);

is($seq->to_string, '[a][b]', 'Stringification');
ok($seq = $seq->normalize, 'Normalization');
is($seq->to_string, '[a][b]', 'Stringification');


# [a][b][c]
$seq = $qb->seq(
  $qb->token('a'),
  $qb->token('b'),
  $qb->token('c')
);

is($seq->to_string, '[a][b][c]', 'Stringification');
ok($seq = $seq->normalize, 'Normalization');
is($seq->to_string, '[a][b][c]', 'Stringification');
ok($seq = $seq->finalize, 'Finalization');
is($seq->to_string, '[a][b][c]', 'Stringification');


# Remove null queries
# [a]-[b]-
$seq = $qb->seq(
  $qb->token('a'),
  $qb->null,
  $qb->token('b'),
  $qb->null
);

is($seq->to_string, '[a]-[b]-', 'Stringification');
ok($seq = $seq->normalize, 'Normalization');
is($seq->to_string, '[a][b]', 'Stringification');
ok($seq = $seq->finalize, 'Finalization');
is($seq->to_string, '[a][b]', 'Stringification');


# Flatten subsequences
$seq = $qb->seq(
  $qb->token('a'),
  $qb->seq(
    $qb->token('b'),
    $qb->token('c')
  )
);

is($seq->to_string, '[a][b][c]', 'Stringification');
is($seq->size, 2, 'Number of operands');

# Flatten
ok($seq = $seq->normalize, 'Normalization');
is($seq->to_string, '[a][b][c]', 'Stringification');
is($seq->size, 3, 'Number of operands');
ok($seq = $seq->finalize, 'Finalization');
is($seq->to_string, '[a][b][c]', 'Stringification');


# Flatten subsequences (2)
$seq = $qb->seq(
  $qb->token('a'),
  $qb->seq(
    $qb->token('b'),
    $qb->token('c'),
    $qb->token('d')
  ),
  $qb->seq(
    $qb->token('e'),
    $qb->token('f'),
  )
);

is($seq->to_string, '[a][b][c][d][e][f]', 'Stringification');
is($seq->size, 3, 'Number of operands');

# Flatten
ok($seq = $seq->normalize, 'Normalization');
is($seq->to_string, '[a][b][c][d][e][f]', 'Stringification');
is($seq->size, 6, 'Number of operands');
ok($seq = $seq->finalize, 'Finalization');
is($seq->to_string, '[a][b][c][d][e][f]', 'Stringification');

# [a]
$seq = $qb->seq(
  $qb->token('a')
);

is($seq->to_string, '[a]', 'Stringification');
ok($seq = $seq->normalize, 'Normalization');
is($seq->to_string, 'a', 'Stringification');
ok($seq = $seq->finalize, 'Normalization');
is($seq->to_string, 'a', 'Stringification');


# Solve left extension
# [][a]
$seq = $qb->seq(
  $qb->token,
  $qb->token('a')
);

is($seq->to_string, '[][a]', 'Stringification');
ok($seq = $seq->normalize, 'Normalization');
is($seq->to_string, '[][a]', 'Stringification');
#ok($seq = $seq->finalize, 'Normalization');
#is($seq->to_string, 'a', 'Stringification');

warn '********************************';

done_testing;
__END__
