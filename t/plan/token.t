use Test::More;
use strict;
use warnings;
use Data::Dumper;

use_ok('Krawfish::Koral');
# use_ok('Krawfish::Index');

# my $index = Krawfish::Index->new;

# ok(defined $index->add('t/data/doc1.jsonld'), 'Add new document');

my $koral = Krawfish::Koral->new;

my $builder = $koral->query_builder;


# [Der]
my $query = $builder->token('Der');
ok(!$query->is_any, 'Isn\'t any');
ok(!$query->is_optional, 'Isn\'t optional');
ok(!$query->is_null, 'Isn\'t null');
ok(!$query->is_negative, 'Isn\'t negative');
ok(!$query->is_extended, 'Isn\'t extended');
is($query->to_string, '[Der]', 'Stringification');
ok($query = $query->normalize, 'Normalization');
is($query->to_string, 'Der', 'Stringification');


# []
$query = $builder->token;
ok($query->is_any, 'Is any');
ok(!$query->is_optional, 'Isn\'t optional');
ok(!$query->is_null, 'Isn\'t null');
ok(!$query->is_negative, 'Isn\'t negative');
ok(!$query->is_extended, 'Isn\'t extended');
is($query->to_string, '[]', 'Stringification');
ok($query = $query->normalize, 'Normalization');
is($query->to_string, '[]', 'Stringification');


# a|!a -> 1
$query = $builder->token(
  $builder->term_or(
    $builder->term('a'),
    $builder->term_neg('a')
  )
);
is($query->to_string, '[!a|a]', 'Stringification');
ok($query = $query->normalize, 'Normalization');
is($query->to_string, '[]', 'Stringification');


# a&!a -> 0
$query = $builder->token(
  $builder->term_and(
    $builder->term('a'),
    $builder->term_neg('a')
  )
);
is($query->to_string, '[!a&a]', 'Stringification');
ok($query = $query->normalize, 'Normalization');
is($query->to_string, '[0]', 'Stringification');


# a|!a -> 1
$query = $builder->token(
  $builder->term_and(
    $builder->term_or(
      $builder->term('a'),
      $builder->term_neg('a')
    ),
    $builder->term('c')
  )
);

is($query->to_string, '[(!a|a)&c]', 'Stringification');
ok($query = $query->normalize, 'Normalization');
is($query->to_string, 'c', 'Stringification');


# a&!a -> 0
$query = $builder->token(
  $builder->term_or(
    $builder->term_and(
      $builder->term('a'),
      $builder->term_neg('a')
    ),
    $builder->term('c')
  )
);

is($query->to_string, '[(!a&a)|c]', 'Stringification');
ok($query = $query->normalize, 'Normalization');
is($query->to_string, 'c', 'Stringification');


# a & a -> a
$query = $builder->token(
  $builder->term_and(
    $builder->term('c'),
    $builder->term('a'),
    $builder->term('c')
  )
);

is($query->to_string, '[a&c&c]', 'Stringification');
ok($query = $query->normalize, 'Normalization');
is($query->to_string, 'a&c', 'Stringification');


# (a|b) & (b|a) -> (a|b)
$query = $builder->token(
  $builder->term_and(
    $builder->term_or(
      $builder->term('a'),
      $builder->term('b')
    ),
    $builder->term_or(
      $builder->term('b'),
      $builder->term('a')
    )
  )
);

is($query->to_string, '[(a|b)&(a|b)]', 'Stringification');
ok($query = $query->normalize, 'Normalization');
is($query->to_string, 'a|b', 'Stringification');


# a | a -> a
$query = $builder->token(
  $builder->term_or(
    $builder->term('c'),
    $builder->term('a'),
    $builder->term('c')
  )
);

is($query->to_string, '[a|c|c]', 'Stringification');
ok($query = $query->normalize, 'Normalization');
is($query->to_string, 'a|c', 'Stringification');


# a & (a | b) -> a
$query = $builder->token(
  $builder->term_and(
    $builder->term('a'),
    $builder->term_or(
      $builder->term('a'),
      $builder->term('b')
    )
  )
);

is($query->to_string, '[a&(a|b)]', 'Stringification');
ok($query = $query->normalize, 'Normalization');
is($query->to_string, 'a', 'Stringification');



# (a&b) | (b&a) -> (a&b)
$query = $builder->token(
  $builder->term_or(
    $builder->term_and(
      $builder->term('a'),
      $builder->term('b')
    ),
    $builder->term_and(
      $builder->term('b'),
      $builder->term('a')
    )
  )
);

is($query->to_string, '[(a&b)|(a&b)]', 'Stringification');
ok($query = $query->normalize, 'Normalization');
is($query->to_string, 'a&b', 'Stringification');



# a | (a & b) -> a
$query = $builder->token(
  $builder->term_or(
    $builder->term('a'),
    $builder->term_and(
      $builder->term('a'),
      $builder->term('b')
    )
  )
);

is($query->to_string, '[a|(a&b)]', 'Stringification');
ok($query = $query->normalize, 'Normalization');
is($query->to_string, 'a', 'Stringification');


# complex
# a & !a -> 0
$query = $builder->token(
  $builder->term_and(
    $builder->term_or(
      $builder->term('a'),
      $builder->term('b')
    ),
    $builder->term_or(
      $builder->term('b'),
      $builder->term('a')
    )->toggle_negative
  )
);

is($query->to_string, '[(!(a|b))&(a|b)]', 'Stringification');
ok($query = $query->normalize, 'Normalization');
is($query->to_string, '[0]', 'Stringification');


# complex
# a | !a -> 1
$query = $builder->token(
  $builder->term_or(
    $builder->term_and(
      $builder->term('a'),
      $builder->term('b')
    ),
    $builder->term_and(
      $builder->term('b'),
      $builder->term('a')
    )->toggle_negative
  )
);

is($query->to_string, '[(!(a&b))|(a&b)]', 'Stringification');
ok($query = $query->normalize, 'Normalization');
is($query->to_string, '[]', 'Stringification');


# (a&!b)|(b&c)
$query = $builder->token(
  $builder->term_or(
    $builder->term_and('aa', $builder->term_neg('bb')),
    $builder->term_and('bb', 'cc')
  )
);
is($query->to_string, '[(!bb&aa)|(bb&cc)]', 'Stringification');
ok($query = $query->normalize, 'Normalization');
is($query->to_string, '(bb&cc)|excl(32:aa,bb)', 'Stringification');




done_testing;
__END__
