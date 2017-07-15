use Test::More;
use Test::Krawfish;
use strict;
use warnings;
use Data::Dumper;

use_ok('Krawfish::Koral::Query::Builder');
use_ok('Krawfish::Index');

my $index = Krawfish::Index->new;
ok_index($index, '[a|b][a|b|c][a][b|c]', 'Add complex document');
ok_index($index, '[b][b|c][a]', 'Add complex document');
# c: 3
# a: 4
# b: 5

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
is($seq->to_string, 'ab', 'Stringification');


# [a][b][c]
$seq = $qb->seq(
  $qb->token('a'),
  $qb->token('b'),
  $qb->token('c')
);

is($seq->to_string, '[a][b][c]', 'Stringification');
ok($seq = $seq->normalize, 'Normalization');
is($seq->to_string, 'abc', 'Stringification');
ok($seq = $seq->finalize, 'Finalization');
is($seq->to_string, 'abc', 'Stringification');


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
is($seq->to_string, 'ab', 'Stringification');
ok($seq = $seq->finalize, 'Finalization');
is($seq->to_string, 'ab', 'Stringification');


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
is($seq->to_string, 'abc', 'Stringification');
is($seq->size, 3, 'Number of operands');
ok($seq = $seq->finalize, 'Finalization');
is($seq->to_string, 'abc', 'Stringification');


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
is($seq->to_string, 'abcdef', 'Stringification');
is($seq->size, 6, 'Number of operands');
ok($seq = $seq->finalize, 'Finalization');
is($seq->to_string, 'abcdef', 'Stringification');

# Not found
ok($seq = $seq->optimize($index), 'Optimization');
is($seq->to_string, '[0]', 'Stringification');


# [a]
$seq = $qb->seq(
  $qb->token('a')
);

is($seq->to_string, '[a]', 'Stringification');
ok($seq = $seq->normalize, 'Normalization');
is($seq->to_string, 'a', 'Stringification');
ok($seq = $seq->finalize, 'Normalization');
is($seq->to_string, 'a', 'Stringification');


# Non sequence is solved
$seq = $qb->seq(
  $qb->repeat($qb->token('a'),0,4)
);
is($seq->to_string, '[a]{0,4}', 'Stringification');
ok($seq = $seq->normalize, 'Normalization');
is($seq->to_string, 'a{0,4}', 'Stringification');
ok($seq = $seq->finalize, 'Normalization');
is($seq->to_string, 'a{1,4}', 'Stringification');
ok($seq->has_warning, 'Has warnings');


TODO: {
  local $TODO = 'Repetition simplification not yet implemented';
  # [a][a][a] -> [a]{3}
  my $seq = $qb->seq(
    $qb->token('a'),
    $qb->token('a'),
    $qb->token('a')
  );
  is($seq->to_string, '[a][a][a]', 'Stringification');
  ok($seq = $seq->normalize, 'Normalization');
  is($seq->to_string, 'a{3}', 'Stringification');

  # [][][]{3} -> []{5}
  # [a]{2}[a] -> [a]{3}
  # [a][a]{2} -> [a]{3}
  # [a]{0,3}[a] -> [a]{1,4}
  # [c][a][b][a][b] -> [c]([a][b]){2}
  # ([a][b]){1,3}[a][b] -> ([a][b]){2,4}
  # [a]{0,100}[a] -> [a]{1,100}
};


# Check optimize:
my $compare = \&Krawfish::Koral::Util::Sequential::_compare;
my $queries = [[1,5], [1,1]];
is($compare->($queries, 0,1), 1, 'simple compare');
is($compare->($queries, 1,0), -1, 'simple compare');

$queries = [[1,5], [1,5], [1,2]];
is($compare->($queries, 1,2), 1, 'simple compare');
is($compare->($queries, 2,1), -1, 'simple compare');
is($compare->($queries, 0,1), 1, 'simple compare');
is($compare->($queries, 1,0), -1, 'simple compare');

# Third operand is the center
$queries = [[1,5], [1,2], [1,5], [1,2], [1,5]];
is($compare->($queries, 1,3), -1, 'simple compare');
is($compare->($queries, 3,1), -1, 'simple compare');
is($compare->($queries, 4,0), -1, 'simple compare');
is($compare->($queries, 0,4), -1, 'simple compare');
is($compare->($queries, 0,2), 1, 'simple compare');
is($compare->($queries, 2,0), -1, 'simple compare');

my $best_pair = \&Krawfish::Koral::Util::Sequential::_get_best_pair;
my ($x, $y) = $best_pair->([[1,5], [1,2], [1,5], [1,2], [1,5]]);
is($x, 3, 'Pair');
is($y, 1, 'Pair');

($x, $y) = $best_pair->([[1,5], [1,2], [1,5]]);
is($x, 1, 'Pair');
is($y, 0, 'Pair');

($x, $y) = $best_pair->([[1,5], [1,2], [1,5]]);
is($x, 1, 'Pair');
is($y, 0, 'Pair');

($x, $y) = $best_pair->([[1,2], [1,2], [1,2]]);
is($x, 1, 'Pair');
is($y, 0, 'Pair');

($x, $y) = $best_pair->([[0,1], [1,2], [1,2], [0,6], [0,7], [1,2]]);
is($x, 2, 'Pair');
is($y, 1, 'Pair');


# Group anchors
# [a][c][b]
$seq = $qb->seq(
  $qb->token('a'),
  $qb->token('c'),
  $qb->token('b')
);
is($seq->to_string, '[a][c][b]', 'Stringification');
ok($seq = $seq->normalize->finalize, 'Normalization');
is($seq->to_string, 'acb', 'Stringification');
ok($seq = $seq->optimize($index), 'Normalization');

# Do not check for stringifications
is($seq->to_string, "constr(pos=2048:'b',constr(pos=2:'a','c'))", 'Stringification');

# Matches nowhere
matches($seq, [], 'Matches nowhere');



# Group anchors
# [a][b][c]
$seq = $qb->seq(
  $qb->token('a'),
  $qb->token('b'),
  $qb->token('c')
);
is($seq->to_string, '[a][b][c]', 'Stringification');
ok($seq = $seq->normalize->finalize, 'Normalization');
is($seq->to_string, 'abc', 'Stringification');
ok($seq = $seq->optimize($index), 'Normalization');

# Do not check for stringifications
is($seq->to_string, "constr(pos=2:'a',constr(pos=2:'b','c'))", 'Stringification');

# Matches nowhere
matches($seq, [], 'Matches nowhere');


# Group anchors
# [b][b][c]
$seq = $qb->seq(
  $qb->token('b'),
  $qb->token('b'),
  $qb->token('a')
);
is($seq->to_string, '[b][b][a]', 'Stringification');
ok($seq = $seq->normalize->finalize, 'Normalization');
is($seq->to_string, 'bba', 'Stringification');
ok($seq = $seq->optimize($index), 'Normalization');

# Do not check for stringifications
is($seq->to_string, "constr(pos=2:'b',constr(pos=2:'b','a'))", 'Stringification');

# Matches twice
matches($seq, [qw/[0:0-3] [1:0-3]/], 'Matches twice');



# Create with ANY distance
# [b][][c]
$seq = $qb->seq(
  $qb->token('a'),
  $qb->token,
  $qb->token('b')
);
is($seq->to_string, '[a][][b]', 'Stringification');
ok($seq = $seq->normalize->finalize, 'Normalization');
is($seq->to_string, 'a[]b', 'Stringification');

ok($seq = $seq->optimize($index), 'Optimization');

# Do not check for stringifications
is($seq->to_string, "constr(pos=4096,between=1-1:'b','a')",
   'Stringification');

# Matches once
matches($seq, [qw/[0:1-4]/], 'Matches Once');

TODO: {
  local $TODO = 'Support different ANY variants';
  #   [b][]?[c]
  #   [b][]{1,3}[c]
  #   [b][]*[c]
  #   [b]{[]*}[c]
};



# Create with NEGATIVE distance
# [b][!a][a]
$seq = $qb->seq(
  $qb->token('b'),
  $qb->token('a')->is_negative(1),
  $qb->token('a')
);
is($seq->to_string, '[b][!a][a]', 'Stringification');
ok($seq = $seq->normalize->finalize, 'Normalization');
is($seq->to_string, 'b[!a]a', 'Stringification');

ok($seq = $seq->optimize($index), 'Optimization');

# Do not check for stringifications
is($seq->to_string, "constr(pos=1,notBetween='a':'b','a')", 'Stringification');

# Matches once
matches($seq, [qw/[1:0-3]/], 'Matches Once');



# Create with NEGATIVE optional distance
# [b][!a]?[a]
$seq = $qb->seq(
  $qb->token('b'),
  $qb->repeat($qb->token('a')->is_negative(1), 0, 1),
  $qb->token('a')
);
is($seq->to_string, '[b][!a]?[a]', 'Stringification');
ok($seq = $seq->normalize->finalize, 'Normalization');
is($seq->to_string, 'b[!a]?a', 'Stringification');
ok($seq = $seq->optimize($index), 'Optimization');

# Do not check for stringifications
is($seq->to_string, "constr(pos=3,between=0-INF,notBetween='a':'b','a')", 'Stringification');

# Matches
matches($seq, [qw/[0:0-2] [0:1-3] [1:0-3] [1:1-3]/], 'Matches');



TODO: {
  local $TODO = 'Support different NEG variants';
  #   [b][!b]?[c]
  #   [b][!b]{1,3}[c]
  #   [b][!b]*[c]
  #   [b]{[!b]*}[c]
};



done_testing;
__END__


# Remove negative operands
# [a][!e][c]
$seq = $qb->seq(
  $qb->token('a'),
  $qb->token('e')->is_negative(1),
  $qb->token('c')
);
is($seq->to_string, '[a][!e][c]', 'Stringification');
ok($seq = $seq->normalize->finalize, 'Normalization');
is($seq->to_string, '[a][!e][c]', 'Stringification');
ok($seq = $seq->optimize($index), 'Normalization');
is($seq->to_string, '', 'Stringification');


# Solve left extension
# [][a]
$seq = $qb->seq(
  $qb->token,
  $qb->token('a')
);

is($seq->to_string, '[][a]', 'Stringification');
ok($seq = $seq->normalize, 'Normalization');
is($seq->to_string, '[][a]', 'Stringification');
ok($seq = $seq->finalize, 'Normalization');
is($seq->to_string, '[][a]', 'Stringification');

# Solve optionality
$seq = $qb->seq(
  $qb->repeat($qb->token('a'),0,4),
  $qb->token
);

is($seq->to_string, '[a]{0,4}[]', 'Stringification');
ok($seq = $seq->normalize, 'Normalization');
#is($seq->to_string, '[a]{0,4}[]', 'Stringification');
#ok($seq = $seq->finalize, 'Normalization');
#is($seq->to_string, '[a]{1,4}[]', 'Stringification');

  # TODO:
  #
  # Probably call this reduce.
  #
  # 1. Cluster subsequences:
  #    abc    ->  (a(b(c)))
  #    !a!b!c ->  !(a(b(c))) !! That does not work because the meaning is different
  #    [][]   ->  []{2}
  #
  #    Watch out for classes!
  #
  # 2. Look for problem situations
  #    a[]b
  #    a[]*b
  #    a[]+b
  #    a[]
  #    a[]*
  #    a[]+
  #    []a
  #    []*a
  #    []+a
  #    a!bc
  #    a!b*c -> constr(pos=precedes,precedesDirectly;notbetween=!b,opt:a,c)
  #    a!b+c
  #    !ba
  #    !b*a
  #    !b+a
  #    a!b
  #    a!b+
  #    a!b*
  #    a?[]
  #    a?[]*
  #    a?[]+
  #    []a?
  #    []*a?
  #    []+a?
  #
  #    a{1:[]}b
  #    a{1:[]}{2:[]}b
  #    a{1:[]{2,3}{2:[]{0,6}}b
  #
  # !b can be a sequence instead of a token/term
  #
  # Watch out for:
  #    [a][b]?[c] -> ([a][b]|[a])[c] or [a]([a][c]|[c])
  #    [a]?[][b]?
  #
