use Test::More;
use strict;
use warnings;

use_ok('Krawfish::Koral::Query::Builder');

my $qb = Krawfish::Koral::Query::Builder->new;

# ([a][b])|[c]|[d]
my $query = $qb->bool_or(
  $qb->seq($qb->token('a'), $qb->token('b')), $qb->token('c'), $qb->token('d')
);
is($query->to_string, '([a][b])|([c])|([d])', 'or');
is($query->min_span, 1, 'Span Length');
is($query->max_span, 2, 'Span Length');
ok($query = $query->normalize->finalize, 'Normalize');
is($query->to_string, '(ab)|(c)|(d)', 'or');
is($query->min_span, 1, 'Span Length');
is($query->max_span, 2, 'Span Length');

# Deal with optional operands
$query = $qb->bool_or(
  $qb->token('a'),
  $qb->repeat($qb->token('b'),0,1),
  $qb->repeat($qb->token('d'),0,1)
);
is($query->to_string, '([a])|([b]?)|([d]?)', 'or');
ok($query = $query->normalize, 'Normalize');
is($query->to_string, '((a)|(b)|(d))?', 'or');
ok($query = $query->finalize, 'Finalize');
is($query->to_string, '(a)|(b)|(d)', 'or');


# Wrap class
$query = $qb->bool_or(
  $qb->class($qb->token('a'),1), $qb->class($qb->token('b'), 1)
);
is($query->to_string, '({1:[a]})|({1:[b]})', 'or with classes');
ok($query = $query->normalize, 'Normalize');
is($query->to_string, '{1:a|b}', 'or with classes');



TODO: {
  local $TODO = 'Test more systematically and with negative operands';
};

done_testing;
