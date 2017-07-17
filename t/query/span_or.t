use Test::More;
use Test::Krawfish;
use strict;
use warnings;
use Data::Dumper;
use File::Basename 'dirname';
use File::Spec::Functions 'catfile';

use_ok('Krawfish::Index');
use_ok('Krawfish::Koral::Query::Builder');

ok(my $qb = Krawfish::Koral::Query::Builder->new, 'Create Koral::Builder');
my $index = Krawfish::Index->new;
ok_index($index, '[a|b][a|b|c][a][b|c]', 'Add complex document');
ok_index($index, '[b][b|c][a]', 'Add complex document');

my $query = $qb->span_or(
  $qb->token('a'), $qb->token('b'), $qb->token('c')
);
is($query->to_string, '([a])|([b])|([c])', 'or');
ok($query = $query->normalize->finalize, 'Normalize');
is($query->to_string, '(a)|(b)|(c)', 'or');

# Flatten groups
$query = $qb->span_or(
  $qb->token('a'), $qb->span_or($qb->token('b'), $qb->token('c'))
);
is($query->to_string, '(([b])|([c]))|([a])', 'termGroup');
ok($query = $query->normalize->finalize, 'Normalize');
is($query->to_string, '(a)|(b)|(c)', 'or');
ok($query = $query->optimize($index), 'Optimize');

matches($query, [qw/[0:0-1] [0:0-1] [0:1-2] [0:1-2] [0:1-2] [0:2-3] [0:3-4] [0:3-4] [1:0-1] [1:1-2] [1:1-2] [1:2-3]/]);


# Remove nulls and nothing
$query = $qb->span_or(
  $qb->nothing, $qb->span_or($qb->token('b'), $qb->token('c')), $qb->null
);
is($query->to_string, '(([b])|([c]))|(-)|([0])', 'span or');
ok($query = $query->normalize->finalize, 'Normalize');
is($query->to_string, '(b)|(c)', 'or');
ok($query = $query->optimize($index), 'Optimize');
matches($query, [qw/[0:0-1] [0:1-2] [0:1-2] [0:3-4] [0:3-4] [1:0-1] [1:1-2] [1:1-2]/]);

# Add different length sequences
$query = $qb->span_or(
  $qb->span_or($qb->token('a'), $qb->seq($qb->token('b'), $qb->token('a')))
);
is($query->to_string, '(([a])|([b][a]))', 'termGroup');
ok($query = $query->normalize->finalize, 'Normalize');
is($query->to_string, '(a)|(ba)', 'or');
ok($query = $query->optimize($index), 'Optimize');
is($query->to_string, "or('a',constr(pos=2:'b','a'))", 'or');

matches($query, [qw/[0:0-1] [0:0-2] [0:1-2] [0:1-3] [0:2-3] [1:1-3] [1:2-3]/]);


done_testing;
