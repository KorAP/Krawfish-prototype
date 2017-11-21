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


# Create with ANY distance
# [a][][b]
my $seq = $qb->seq(
  $qb->token('a'),
  $qb->token,
  $qb->token('b')
);
is($seq->to_string, '[a][][b]', 'Stringification');
ok($seq = $seq->normalize->finalize, 'Normalization');
is($seq->to_string, 'a[]b', 'Stringification');

ok($seq = $seq->identify($index->dict)->optimize($index->segment), 'Optimization');

# Do not check for stringifications
is($seq->to_string, "constr(pos=4096,between=1-1:#3,#2)",
   'Stringification');

# Matches once
matches($seq, [qw/[0:1-4]/], 'Matches Once');


# Create with optional ANY distance
# [b][]?[c]
$seq = $qb->seq(
  $qb->token('a'),
  $qb->repeat($qb->token, 0, 1),
  $qb->token('b')
);
is($seq->to_string, '[a][]?[b]', 'Stringification');
ok($seq = $seq->normalize->finalize, 'Normalization');
is($seq->to_string, 'a[]?b', 'Stringification');
ok($seq = $seq->identify($index->dict)->optimize($index->segment), 'Optimization');

# Do not check for stringifications
is($seq->to_string, "constr(pos=6144,between=0-1:#3,#2)",
   'Stringification');

# Matches once
matches($seq, [qw/[0:0-2] [0:1-4] [0:2-4]/], 'Matches Once');



# Create with ranged ANY distance
# [b][]{1,3}[c]
$seq = $qb->seq(
  $qb->token('a'),
  $qb->repeat($qb->token, 1, 3),
  $qb->token('b')
);
is($seq->to_string, '[a][]{1,3}[b]', 'Stringification');
ok($seq = $seq->normalize->finalize, 'Normalization');
is($seq->to_string, 'a[]{1,3}b', 'Stringification');
ok($seq = $seq->identify($index->dict)->optimize($index->segment), 'Optimization');

# Do not check for stringifications
is($seq->to_string, "constr(pos=4096,between=1-3:#3,#2)",
   'Stringification');

# Matches once
matches($seq, [qw/[0:0-4] [0:1-4]/], 'Matches Once');

# [a][]*[b]
$seq = $qb->seq(
  $qb->token('a'),
  $qb->repeat($qb->token, 0, undef),
  $qb->token('b')
);
is($seq->to_string, '[a][]*[b]', 'Stringification');
ok($seq = $seq->normalize->finalize, 'Normalization');
is($seq->to_string, 'a[]{0,100}b', 'Stringification');
ok($seq = $seq->identify($index->dict)->optimize($index->segment), 'Optimization');

# Do not check for stringifications
is($seq->to_string, "constr(pos=6144,between=0-100:#3,#2)",
   'Stringification');

# Matches once
matches($seq, [qw/[0:0-2] [0:0-4] [0:1-4] [0:2-4]/], 'Matches Once');


# [a]{[]*}[b]
$seq = $qb->seq(
  $qb->token('a'),
  $qb->class($qb->repeat($qb->token, 0, undef)),
  $qb->token('b')
);
is($seq->to_string, '[a]{1:[]*}[b]', 'Stringification');
ok($seq = $seq->normalize->finalize, 'Normalization');
is($seq->to_string, 'a{1:[]{0,100}}b', 'Stringification');
ok($seq = $seq->identify($index->dict)->optimize($index->segment), 'Optimization');

# Do not check for stringifications
is($seq->to_string, "constr(pos=6144,between=0-100,class=1:#3,#2)",
   'Stringification');

# Matches once
matches($seq, ['[0:0-2]','[0:0-4$0,1,1,2]','[0:1-4$0,1,2,2]','[0:2-4]'], 'Matches Once');


# Create with multiple classes optional distance
# [a]{3:{4:[]*}}[b]
$seq = $qb->seq(
  $qb->token('a'),
  $qb->class($qb->class($qb->repeat($qb->anywhere,0,undef),3),4),
  $qb->token('b')
);
is($seq->to_string, '[a]{4:{3:[]*}}[b]', 'Stringification');
ok($seq = $seq->normalize->finalize, 'Normalization');
is($seq->to_string, 'a{4:{3:[]{0,100}}}b', 'Stringification');
ok($seq = $seq->identify($index->dict)->optimize($index->segment), 'Optimization');

# Do not check for stringifications
is($seq->to_string, "constr(pos=6144,between=0-100,class=4,class=3:#3,#2)",
   'Stringification');


# Create with multiple classes optional distance in reverse ordering
# [a]{3:{4:[]*}}[b]
$seq = $qb->seq(
  $qb->token('a'),
  $qb->repeat($qb->class($qb->class($qb->anywhere,3),4),0,undef),
  $qb->token('b')
);
is($seq->to_string, '[a]{4:{3:[]}}*[b]', 'Stringification');
ok($seq = $seq->normalize->finalize, 'Normalization');
is($seq->to_string, 'a{4:{3:[]{0,100}}}b', 'Stringification');
ok($seq = $seq->identify($index->dict)->optimize($index->segment), 'Optimization');

# Do not check for stringifications
is($seq->to_string, "constr(pos=6144,between=0-100,class=4,class=3:#3,#2)",
   'Stringification');


# Deal with classed anywhere sequences
# [a]{1:[][]}[b]
$seq = $qb->seq(
  $qb->token('a'),
  $qb->class(
    $qb->seq(
      $qb->anywhere,
      $qb->anywhere
    ),
    1
  ),
  $qb->token('b')
);

# TODO: This should be optimized away to be a repetition query
is($seq->to_string, '[a]{1:[][]}[b]', 'Stringification');
ok($seq = $seq->normalize, 'Normalization');
is($seq->to_string, 'a{1:[]{2}}b', 'Stringification');
ok($seq->has_warning, 'Query has warnings');
ok($seq = $seq->finalize, 'Finalization');
is($seq->to_string, 'a{1:[]{2}}b', 'Stringification');


# Create complex ANY group
# [a]{1:[]{2:[]*}}[b]
$seq = $qb->seq(
  $qb->token('a'),
  $qb->class(
    $qb->seq(
      $qb->anywhere,
      $qb->class(
        $qb->repeat($qb->anywhere,0,undef),
        2
      ),
    ),
    1
  ),
  $qb->token('b')
);

is($seq->to_string, '[a]{1:[]{2:[]*}}[b]', 'Stringification');
ok($seq = $seq->normalize, 'Normalization');
ok($seq->has_warning, 'Query has warnings');
is($seq->to_string, 'a{1:[]{1,100}}b', 'Stringification');
ok($seq = $seq->finalize, 'Finalization');
is($seq->to_string, 'a{1:[]{1,100}}b', 'Stringification');


TODO: {
  local $TODO = 'Support ANY groups variants';

};

done_testing;
__END__
