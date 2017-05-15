use Test::More;
use Test::Krawfish;
use strict;
use warnings;

use_ok('Krawfish::Koral::Corpus::Builder');

ok(my $cb = Krawfish::Koral::Corpus::Builder->new, 'Create CorpusBuilder');

# Get tree
my $tree = $cb->field_and(
  $cb->string('age')->eq('4'),
  $cb->string('author')->eq('Peter'),
  undef,
  $cb->string('age')->eq('4')
);

# Remove empty elements
$tree->planned_tree;
is($tree->to_string, 'age=4&author=Peter', 'Resolve idempotence');


# Solve grouping
$tree = $cb->field_and(
  $cb->string('a')->eq('1'),
  $cb->field_and(
    $cb->string('b')->eq('2'),
    $cb->string('c')->eq('3'),
    $cb->field_and(
      $cb->string('d')->eq('4'),
      $cb->string('d')->eq('4'),
      $cb->string('e')->eq('5'),
    )
  )
);

is($tree->to_string, 'a=1&(b=2&c=3&(d=4&d=4&e=5))', 'Plain groups');
$tree->planned_tree;
is($tree->to_string, 'a=1&b=2&c=3&d=4&e=5', 'Remove empty');


# Solve grouping with reverse groups
$tree = $cb->field_and(
  $cb->string('a')->eq('1'),
  $cb->field_and(
    $cb->string('b')->eq('2'),
    $cb->string('c')->eq('3'),
    $cb->field_or(
      $cb->string('d')->eq('4'),
      $cb->string('d')->eq('4'),
      $cb->string('e')->eq('5'),
    )
  )
);

is($tree->to_string, 'a=1&(b=2&c=3&(d=4|d=4|e=5))', 'Plain groups');
$tree->planned_tree;
is($tree->to_string, 'a=1&b=2&c=3&(d=4|e=5)', 'Remove empty');


# Solve nested idempotence
$tree = $cb->field_and(
  $cb->string('c')->eq('1'),
  $cb->string('a')->eq('1'),
  $cb->field_or(
    $cb->string('a')->eq('1'),
    $cb->string('b')->eq('1')
  )
);

is($tree->to_string, 'a=1&(a=1|b=1)&c=1', 'Plain groups');
$tree->planned_tree;
is($tree->to_string, 'a=1&c=1', 'Remove empty');


# Solve nested idempotence
$tree = $cb->field_and(
  $cb->string('x')->eq('1'),
  $cb->string('z')->eq('1'),
  $cb->field_or(
    $cb->string('a')->eq('1'),
    $cb->string('a')->eq('1'),
    $cb->string('z')->eq('1')
  ),
  $cb->field_or(
    $cb->string('f')->eq('1'),
    $cb->string('g')->eq('1')
  ),
  $cb->string('b')->eq('1'),
  $cb->field_or(
    $cb->string('a')->eq('1'),
    $cb->string('x')->eq('1')
  )
);

is($tree->to_string, '(a=1|a=1|z=1)&(a=1|x=1)&b=1&(f=1|g=1)&x=1&z=1', 'Plain groups');
$tree->planned_tree;
is($tree->to_string, 'b=1&(f=1|g=1)&x=1&z=1', 'Remove empty');


# Remove negative idempotence in AND
$tree = $cb->field_and(
  $cb->string('a')->eq('1'),
  $cb->string('a')->ne('1')
);

is($tree->to_string, 'a!=1&a=1', 'Plain groups');
$tree->planned_tree;
ok($tree->is_nothing, 'Matches nowhere');
ok(!$tree->is_any, 'Matches everywhere');
is($tree->to_string, '', 'Remove empty');

$tree = $cb->field_or(
  $cb->string('x')->eq('1'),
  $cb->string('z')->eq('1'),
  $cb->field_and(
    $cb->string('a')->eq('1'),
    $cb->string('a')->ne('1')
  ),
);

is($tree->to_string, '(a!=1&a=1)|x=1|z=1', 'Plain groups');
$tree->planned_tree;
is($tree->to_string, 'x=1|z=1', 'Remove empty');


# Remove negative idempotence in OR
$tree = $cb->field_or(
  $cb->string('a')->eq('1'),
  $cb->string('a')->ne('1')
);

is($tree->to_string, 'a!=1|a=1', 'Plain groups');
$tree->planned_tree;
ok($tree->is_any, 'Matches everywhere');
ok(!$tree->is_nothing, 'Matches nowhere');
is($tree->to_string, '', 'Remove empty');

$tree = $cb->field_or(
  $cb->string('x')->eq('1'),
  $cb->string('z')->eq('1'),
  $cb->field_and(
    $cb->string('a')->eq('1'),
    $cb->string('a')->ne('1')
  ),
);

is($tree->to_string, '(a!=1&a=1)|x=1|z=1', 'Plain groups');
$tree->planned_tree;
is($tree->to_string, 'x=1|z=1', 'Remove empty');


# Check flattening with NOTHING
$tree = $cb->field_or(
  $cb->string('x')->eq('1'),
  $cb->nothing,
  $cb->string('z')->eq('1'),
);

is($tree->to_string, '[0]|x=1|z=1', 'Plain groups');
$tree->planned_tree;
ok(!$tree->is_nothing, 'No Nothing');
is($tree->to_string, 'x=1|z=1', 'Remove empty');

$tree = $cb->field_and(
  $cb->string('x')->eq('1'),
  $cb->nothing,
  $cb->string('z')->eq('1'),
);

is($tree->to_string, '[0]&x=1&z=1', 'Plain groups');
$tree->planned_tree;
ok($tree->is_nothing, 'Nothing');
is($tree->to_string, '', 'Nothing');

$tree = $cb->field_or(
  $cb->string('x')->eq('1'),
  $cb->nothing,
  $cb->string('z')->eq('1'),
);

is($tree->to_string, '[0]|x=1|z=1', 'Plain groups');
$tree->planned_tree;
ok(!$tree->is_nothing, 'Nothing');
is($tree->to_string, 'x=1|z=1', 'Nothing');


# Check flattening with ANY
$tree = $cb->field_or(
  $cb->string('x')->eq('1'),
  $cb->any,
  $cb->string('z')->eq('1'),
);

is($tree->to_string, '[1]|x=1|z=1', 'Plain groups');
$tree->planned_tree;
ok(!$tree->is_nothing, 'No Nothing');
ok($tree->is_any, 'Anything');
is($tree->to_string, '', 'no string');


diag 'Check with negativity';


done_testing;
__END__

# Solve grouping with negative groups
$tree = $cb->field_and(
  $cb->string('a')->eq('1'),
  $cb->field_and(
    $cb->string('b')->eq('2'),
    $cb->string('c')->ne('3'),
    $cb->field_or(
      $cb->string('d')->eq('4'),
      $cb->string('d')->eq('4'),
      $cb->string('e')->eq('5'),
    )
  )
);


$tree = $cb->field_and(
  $cb->string('age')->ne('4'),
  $cb->string('author')->ne('Peter'),
  undef,
  $cb->string('age')->ne('4')
);

$tree->remove_empty->resolve_idempotence;
is($tree->to_string, 'age!=4&author!=Peter', 'Resolve idempotence');

done_testing;
