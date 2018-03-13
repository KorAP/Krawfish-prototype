use Test::More;
use Test::Krawfish;
use strict;
use warnings;

use_ok('Krawfish::Koral::Corpus::Builder');

ok(my $cb = Krawfish::Koral::Corpus::Builder->new, 'Create CorpusBuilder');

my $tree;

# Get tree
$tree = $cb->bool_and(
  $cb->string('age')->eq('4'),
  $cb->string('author')->eq('Peter'),
  undef,
  $cb->string('age')->eq('4')
);


# Remove empty elements
ok($tree = $tree->normalize, 'Query normalization');
is($tree->to_string, 'age=4&author=Peter', 'Resolve idempotence');

# Solve grouping
$tree = $cb->bool_and(
  $cb->string('a')->eq('1'),
  $cb->bool_and(
    $cb->string('b')->eq('2'),
    $cb->string('c')->eq('3'),
    $cb->bool_and(
      $cb->string('d')->eq('4'),
      $cb->string('d')->eq('4'),
      $cb->string('e')->eq('5'),
    )
  )
);

is($tree->to_string, '((d=4&d=4&e=5)&b=2&c=3)&a=1', 'Plain groups');
$tree->normalize;
is($tree->to_string, 'a=1&b=2&c=3&d=4&e=5', 'Remove empty');


# Solve grouping with reverse groups
$tree = $cb->bool_and(
  $cb->string('a')->eq('1'),
  $cb->bool_and(
    $cb->string('b')->eq('2'),
    $cb->string('c')->eq('3'),
    $cb->bool_or(
      $cb->string('d')->eq('4'),
      $cb->string('d')->eq('4'),
      $cb->string('e')->eq('5'),
    )
  )
);

is($tree->to_string, '((d=4|d=4|e=5)&b=2&c=3)&a=1', 'Plain groups');
$tree->normalize;
is($tree->to_string, '(d=4|e=5)&a=1&b=2&c=3', 'Remove empty');


# Solve nested idempotence
$tree = $cb->bool_and(
  $cb->string('c')->eq('1'),
  $cb->string('a')->eq('1'),
  $cb->bool_or(
    $cb->string('a')->eq('1'),
    $cb->string('b')->eq('1')
  )
);

is($tree->to_string, '(a=1|b=1)&a=1&c=1', 'Plain groups');
$tree->normalize;
is($tree->to_string, 'a=1&c=1', 'Remove empty');


# Solve nested idempotence
$tree = $cb->bool_and(
  $cb->string('x')->eq('1'),
  $cb->string('z')->eq('1'),
  $cb->bool_or(
    $cb->string('a')->eq('1'),
    $cb->string('a')->eq('1'),
    $cb->string('z')->eq('1')
  ),
  $cb->bool_or(
    $cb->string('f')->eq('1'),
    $cb->string('g')->eq('1')
  ),
  $cb->string('b')->eq('1'),
  $cb->bool_or(
    $cb->string('a')->eq('1'),
    $cb->string('x')->eq('1')
  )
);

is($tree->to_string, '(a=1|a=1|z=1)&(a=1|x=1)&(f=1|g=1)&b=1&x=1&z=1', 'Plain groups');
$tree->normalize;
is($tree->to_string, '(f=1|g=1)&b=1&x=1&z=1', 'Remove empty');


# Remove negative idempotence in AND
# (a & !a) -> [0]
$tree = $cb->bool_and(
  $cb->string('a')->eq('1'),
  $cb->string('a')->ne('1')
);

is($tree->to_string, 'a!=1&a=1', 'Plain groups');
$tree->normalize;
is($tree->to_string, '', 'Remove empty');

ok($tree->is_nowhere, 'Matches nowhere');
ok(!$tree->is_anywhere, 'Matches everywhere');


$tree = $cb->bool_or(
  $cb->string('x')->eq('1'),
  $cb->string('z')->eq('1'),
  $cb->bool_and(
    $cb->string('a')->eq('1'),
    $cb->string('a')->ne('1')
  ),
);

is($tree->to_string, '(a!=1&a=1)|x=1|z=1', 'Plain groups');
$tree->normalize;
is($tree->to_string, 'x=1|z=1', 'Remove empty');


# Remove negative idempotence in OR
# (a | !a) -> [1]
$tree = $cb->bool_or(
  $cb->string('a')->eq('1'),
  $cb->string('a')->ne('1')
);

is($tree->to_string, 'a!=1|a=1', 'Plain groups');
$tree->normalize;
ok($tree->is_anywhere, 'Matches everywhere');
ok(!$tree->is_nowhere, 'Matches nowhere');
is($tree->to_string, '', 'Remove empty');


# (x | y | (a & !a)) -> (x | y)
$tree = $cb->bool_or(
  $cb->string('x')->eq('1'),
  $cb->string('z')->eq('1'),
  $cb->bool_and(
    $cb->string('a')->eq('1'),
    $cb->string('a')->ne('1')
  ),
);

is($tree->to_string, '(a!=1&a=1)|x=1|z=1', 'Plain groups');
$tree->normalize;
is($tree->to_string, 'x=1|z=1', 'Remove empty');


# Check flattening with NOWHERE
# ([0] | a) -> a
$tree = $cb->bool_or(
  $cb->string('x')->eq('1'),
  $cb->nowhere,
  $cb->string('z')->eq('1'),
);


is($tree->to_string, '[0]|x=1|z=1', 'Plain groups');
$tree->normalize;
ok(!$tree->is_nowhere, 'No Nowhere');
is($tree->to_string, 'x=1|z=1', 'Remove empty');


# ([0] & a) -> [0]
$tree = $cb->bool_and(
  $cb->string('x')->eq('1'),
  $cb->nowhere,
  $cb->string('z')->eq('1'),
);

is($tree->to_string, '[0]&x=1&z=1', 'Plain groups');
ok($tree = $tree->normalize, 'Normalize');
ok($tree->is_nowhere, 'Nowhere');
is($tree->to_string, '[0]', 'Nowhere');


# Check flattening with ANY
# ([1] | a) -> [1]
$tree = $cb->bool_or(
  $cb->string('x')->eq('1'),
  $cb->anywhere,
  $cb->string('z')->eq('1'),
);

is($tree->to_string, '[1]|x=1|z=1', 'Plain groups');
ok($tree = $tree->normalize, 'Normalize');
ok(!$tree->is_nowhere, 'No Nowhere');
ok($tree->is_anywhere, 'Anything');
is($tree->to_string, '[1]', 'no string');


# Check flattening with ANY
# ([1] & a) -> a
$tree = $cb->bool_and(
  $cb->string('x')->eq('1'),
  $cb->anywhere,
  $cb->string('z')->eq('1'),
);

is($tree->to_string, '[1]&x=1&z=1', 'Plain groups');
ok($tree = $tree->normalize, 'Normalize');
ok(!$tree->is_nowhere, 'No Nowhere');
ok(!$tree->is_anywhere, 'No Anything');
is($tree->to_string, 'x=1&z=1', 'no string');


# DeMorgan simple with OR
# (!a | !b) -> !(a & b)
$tree = $cb->bool_or(
  $cb->string('x')->ne('1'),
  $cb->string('y')->ne('1'),
  $cb->string('z')->ne('1'),
);

is($tree->to_string, 'x!=1|y!=1|z!=1', 'Plain groups');
ok($tree = $tree->normalize, 'Normalize');
is($tree->to_string, '!(x=1&y=1&z=1)', 'no string');


# DeMorgan simple with AND
# (!a & !b) -> !(a | b)
$tree = $cb->bool_and(
  $cb->string('x')->ne('1'),
  $cb->string('y')->ne('1'),
  $cb->string('z')->ne('1'),
);

is($tree->to_string, 'x!=1&y!=1&z!=1', 'Plain groups');
ok($tree = $tree->normalize, 'Normalize');
is($tree->to_string, '!(x=1|y=1|z=1)', 'no string');


# DeMorgan grouping with OR
$tree = $cb->bool_or(
  $cb->string('a')->ne('1'),
  $cb->string('b')->eq('1'),
  $cb->string('c')->ne('1'),
  $cb->string('d')->eq('1'),
  $cb->string('e')->ne('1'),
  $cb->string('f')->eq('1'),
);

is($tree->to_string, 'a!=1|b=1|c!=1|d=1|e!=1|f=1', 'Plain groups');
ok($tree = $tree->normalize, 'Normalize');
is($tree->to_string, '([1]&!(a=1&c=1&e=1))' . '|b=1|d=1|f=1', 'no string');

# DeMorgan grouping with AND
$tree = $cb->bool_and(
  $cb->string('a')->ne('1'),
  $cb->string('b')->eq('1'),
  $cb->string('c')->ne('1'),
  $cb->string('d')->eq('1'),
  $cb->string('e')->ne('1'),
  $cb->string('f')->eq('1'),
);

is($tree->to_string, 'a!=1&b=1&c!=1&d=1&e!=1&f=1', 'Plain groups');
ok($tree = $tree->normalize, 'Normalize');

# TODO: This may require a direct andNot() serialization with the all-query
is($tree->to_string, '((b=1&d=1&f=1)&!(a=1|c=1|e=1))', 'no string');

# Remove double negativity
# !(!a) -> a
$tree = $cb->bool_and(
  $cb->string('a')->ne('1'),
)->toggle_negative;

is($tree->to_string, '!(a!=1)', 'Plain groups');
ok($tree = $tree->normalize, 'Normalize');
is($tree->to_string, 'a=1', 'simple string');


# Remove double negativity with groups
$tree = $cb->bool_and(
  $cb->string('a')->ne('1'),
  $cb->string('b')->ne('1'),
)->toggle_negative;

is($tree->to_string, '!(a!=1&b!=1)', 'Plain groups');
ok($tree = $tree->normalize, 'Normalize');
is($tree->to_string, 'a=1|b=1', 'simple string');


# Remove double negativity with nested groups (1)
$tree = $cb->bool_and(
  $cb->bool_or(
    $cb->bool_and(
      $cb->string('a')->ne('1'),
      $cb->string('b')->ne('1'),
    )->toggle_negative
  )->toggle_negative
)->toggle_negative;

is($tree->to_string, '!((!((!(a!=1&b!=1)))))', 'Plain groups');
$tree = $tree->normalize;
is($tree->to_string, 'a=1|b=1', 'simple string');


# Remove double negativity with nested groups (2)
$tree = $cb->bool_or(
  $cb->string('b')->ne('1'),
  $cb->bool_and(
    $cb->string('c')->ne('1'),
    $cb->string('d')->ne('1'),
  )->toggle_negative
)->toggle_negative;

is($tree->to_string, '!((!(c!=1&d!=1))|b!=1)', 'Plain groups');
$tree = $tree->normalize;
is($tree->to_string, '!(([1]&!b=1)|c=1|d=1)', 'simple string');
$tree = $tree->finalize;
is($tree->to_string, '([1]&!(([1]&!b=1)|c=1|d=1))', 'simple string');


# Check [1/0]&/|[1/0]
ok($tree = $cb->bool_and(
  $cb->anywhere,
  $cb->anywhere
), "And with everywhere");

is($tree->to_string, '[1]&[1]', 'Stringification');
ok($tree = $tree->normalize, 'Normalization');
is($tree->to_string, '[1]', 'Stringification');
ok($tree->is_anywhere, 'Query is anywhere');
ok($tree = $tree->finalize, 'Planning');
is($tree->to_string, "[1]", 'Stringification');

ok($tree = $cb->bool_and(
  $cb->nowhere,
  $cb->nowhere
), "And with nowhere");

is($tree->to_string, '[0]&[0]', 'Stringification');
ok($tree = $tree->normalize, 'Normalization');
is($tree->to_string, '[0]', 'Stringification');
ok($tree->is_nowhere, 'Is nowhere');
ok($tree = $tree->finalize, 'Planning');
is($tree->to_string, "[0]", 'Stringification');


ok($tree = $cb->bool_or(
  $cb->anywhere,
  $cb->anywhere
), "Or with everywhere");

is($tree->to_string, '[1]|[1]', 'Stringification');
ok($tree = $tree->normalize, 'Normalization');
is($tree->to_string, '[1]', 'Stringification');
ok($tree->is_anywhere, 'Is anywhere');
ok($tree = $tree->finalize, 'Planning');
is($tree->to_string, "[1]", 'Stringification');



ok($tree = $cb->bool_or(
  $cb->nowhere,
  $cb->nowhere
), "Or with nowhere");

is($tree->to_string, '[0]|[0]', 'Stringification');
ok($tree = $tree->normalize, 'Normalization');
is($tree->to_string, '[0]', 'Stringification');
ok($tree->is_nowhere, 'Is nowhere');
ok($tree = $tree->finalize, 'Planning');
is($tree->to_string, "[0]", 'Stringification');



done_testing;
__END__




$tree = $cb->bool_and(
  $cb->string('a')->ne('1'),
  $cb->bool_or(
    $cb->string('b')->ne('1'),
    $cb->bool_and(
      $cb->string('c')->ne('1'),
      $cb->string('d')->ne('1'),
    )->toggle_negative
  )->toggle_negative
)->toggle_negative;

is($tree->to_string, '!((!((!(c!=1&d!=1))|b!=1))&a!=1)', 'Plain groups');
$tree->planned_tree;
is($tree->to_string, '', 'simple string');
# !((!(a=1|c=1|d=1))&b=1)






# Solve grouping with negative groups
$tree = $cb->bool_and(
  $cb->string('a')->eq('1'),
  $cb->bool_and(
    $cb->string('b')->eq('2'),
    $cb->string('c')->ne('3'),
    $cb->bool_or(
      $cb->string('d')->eq('4'),
      $cb->string('d')->eq('4'),
      $cb->string('e')->eq('5'),
    )
  )
);


$tree = $cb->bool_and(
  $cb->string('age')->ne('4'),
  $cb->string('author')->ne('Peter'),
  undef,
  $cb->string('age')->ne('4')
);

$tree->remove_empty->resolve_idempotence;
is($tree->to_string, 'age!=4&author!=Peter', 'Resolve idempotence');






done_testing;
