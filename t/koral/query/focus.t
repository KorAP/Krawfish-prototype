use Test::More;
use Test::Krawfish;
use strict;
use warnings;

use_ok('Krawfish::Koral');
use_ok('Krawfish::Index');

my $koral = Krawfish::Koral->new;
my $qb = $koral->query_builder;


# Focus on existing class
my $query = $qb->focus(
  $qb->seq(
    $qb->token('aa'),
    $qb->class(
      $qb->token('bb'),
      2
    )
  ),
  [2]
);
is($query->to_string, 'focus(2:[aa]{2:[bb]})', 'Stringification');
ok($query = $query->normalize, 'Normalization');
is($query->to_string, 'focus(2:aa{2:bb})', 'Stringification');


# Focussing on a class that
# does not exist
# will result in nowhere
$query = $qb->focus(
  $qb->token('bb'),
  [2,4]
);
is($query->to_string, 'focus(2,4:[bb])', 'Stringification');
ok($query = $query->normalize, 'Normalization');
is($query->to_string, '[0]', 'Stringification');


# Focussing on a class that
# can't exist
# will result in nowhere
$query = $qb->focus(
  $qb->exclusion(
    ['isAround'],
    $qb->span('aa'),
    $qb->class(
      $qb->token('bb'),
      2
    ),
  ),
  [2]
);
is($query->to_string, 'focus(2:excl(isAround:<aa>,{2:[bb]}))', 'Stringification');
ok($query = $query->normalize, 'Normalization');
is($query->to_string, '[0]', 'Stringification');


# Remove nested focusses
$query = $qb->focus(
  $qb->focus(
    $qb->exclusion(
      ['isAround'],
      $qb->class(
        $qb->class(
          $qb->token('bb'),
          2
        ),
        3
      ),
      $qb->span('aa'),
    ),
    [3]
  ),
  [2]
);
is($query->to_string, 'focus(2:focus(3:excl(isAround:{3:{2:[bb]}},<aa>)))', 'Stringification');
ok($query = $query->normalize, 'Normalization');
is($query->to_string, 'focus(2:excl(isAround:{3:{2:bb}},<aa>))', 'Stringification');


# Unnecessary focus on directly nested class
$query = $qb->focus(
  $qb->focus(
    $qb->class(
      $qb->class(
        $qb->token('bb'),
        2
      ),
      3
    ),
    [2]
  ),
  [3]
);
is($query->to_string, 'focus(3:focus(2:{3:{2:[bb]}}))', 'Stringification');
ok($query = $query->normalize, 'Normalization');
is($query->to_string, '{3:{2:bb}}', 'Stringification');



done_testing;
__END__

# TODO:

