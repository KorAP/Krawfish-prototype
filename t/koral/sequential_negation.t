use Test::More;
use Test::Krawfish;
use strict;
use warnings;
use Data::Dumper;

use_ok('Krawfish::Koral::Query::Builder');
use_ok('Krawfish::Index');

my $index = Krawfish::Index->new;
ok_index_2($index, '[a|b][a|b|c][a][b|c]', 'Add complex document');
ok_index_2($index, '[b][b|c][a]', 'Add complex document');
# c: 3
# a: 4
# b: 5

my $qb = Krawfish::Koral::Query::Builder->new;

# Create with NEGATIVE distance
# [b][!a][a]
my $seq = $qb->seq(
  $qb->token('b'),
  $qb->token('a')->is_negative(1),
  $qb->token('a')
);
is($seq->to_string, '[b][!a][a]', 'Stringification');
ok($seq = $seq->normalize->finalize, 'Normalization');
is($seq->to_string, 'b[!a]a', 'Stringification');

ok($seq = $seq->identify($index->dict)->optimize($index->segment), 'Optimization');

# Do not check for stringifications
is($seq->to_string, "constr(pos=1,notBetween=#2:#3,#2)", 'Stringification');

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
ok($seq = $seq->identify($index->dict)->optimize($index->segment), 'Optimization');

# Do not check for stringifications
is($seq->to_string, "constr(pos=3,between=0-INF,notBetween=#2:#3,#2)", 'Stringification');

# Matches
matches($seq, [qw/[0:0-2] [0:1-3] [1:0-3] [1:1-3]/], 'Matches');


TODO: {
  local $TODO = 'Support different NEG variants';
  #   [b][!b]{1,3}[c]
  #   [b][!b]*[c]
  #   [b]{[!b]*}[c]
  #   [b][!z]{0,3}[c] -> [b][c]
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
ok($seq = $seq->identify($index->dict)->optimize($index->segment), 'Normalization');
is($seq->to_string, '', 'Stringification');
