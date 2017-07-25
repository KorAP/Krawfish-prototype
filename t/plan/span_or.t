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

TODO: {
  local $TODO = 'Test more systematically and with negative operands';
};

done_testing;
