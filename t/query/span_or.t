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
ok_index_2($index, '[a|b][a|b|c][a][b|c]', 'Add complex document');
ok_index_2($index, '[b][b|c][a]', 'Add complex document');

my $query = $qb->bool_or(
  $qb->token('a'), $qb->token('b'), $qb->token('c')
);
is($query->to_string, '([a])|([b])|([c])', 'or');
ok($query = $query->normalize->finalize, 'Normalize');
is($query->to_string, '(a)|(b)|(c)', 'or');

# Flatten groups
$query = $qb->bool_or(
  $qb->token('a'), $qb->bool_or($qb->token('b'), $qb->token('c'))
);
is($query->to_string, '(([b])|([c]))|([a])', 'termGroup');
ok($query = $query->normalize->finalize, 'Normalize');
is($query->to_string, '(a)|(b)|(c)', 'or');
ok($query = $query->identify($index->dict)->optimize($index->segment), 'Optimize');

matches($query, [qw/[0:0-1] [0:0-1] [0:1-2] [0:1-2] [0:1-2] [0:2-3] [0:3-4] [0:3-4] [1:0-1] [1:1-2] [1:1-2] [1:2-3]/]);


# Remove nulls and nothing
$query = $qb->bool_or(
  $qb->nothing, $qb->bool_or($qb->token('b'), $qb->token('c')), $qb->null
);
is($query->to_string, '(([b])|([c]))|(-)|([0])', 'span or');
ok($query = $query->normalize->finalize, 'Normalize');
is($query->to_string, '(b)|(c)', 'or');
ok($query = $query->identify($index->dict)->optimize($index->segment), 'Optimize');
matches($query, [qw/[0:0-1] [0:1-2] [0:1-2] [0:3-4] [0:3-4] [1:0-1] [1:1-2] [1:1-2]/]);

# Add different length sequences
$query = $qb->bool_or(
  $qb->bool_or($qb->token('a'), $qb->seq($qb->token('b'), $qb->token('a')))
);
is($query->to_string, '(([a])|([b][a]))', 'termGroup');
ok($query = $query->normalize->finalize, 'Normalize');
is($query->to_string, '(a)|(ba)', 'or');
ok($query = $query->identify($index->dict)->optimize($index->segment), 'Optimize');
# is($query->to_string, "or(#2,constr(pos=2:#3,#2))", 'or');

matches($query, [qw/[0:0-1] [0:0-2] [0:1-2] [0:1-3] [0:2-3] [1:1-3] [1:2-3]/]);

TODO: {
  local $TODO = 'Test with negative operands';
};

done_testing;
