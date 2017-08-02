use Test::More;
use Test::Krawfish;
use strict;
use warnings;

use_ok('Krawfish::Index');
use_ok('Krawfish::Koral::Query::Builder');

my $index = Krawfish::Index->new;
ok_index($index, [qw/aa bb aa bc ac bb cc ca/], 'Add complex document');


# Simple
ok(my $qb = Krawfish::Koral::Query::Builder->new, 'Create Builder');
ok(my $q = $qb->term_re('[ac].'), 'Regex');
ok($q = $q->normalize->finalize, 'Prepare query');
is($q->to_string, "/[ac]./", 'Stringification');
ok($q = $q->identify($index->dict), 'Prepare query');
is($q->to_string, '(#1)|(#4)|(#5)|(#6)', 'Stringification');

ok($q = $q->optimize($index->segment), 'Prepare query');
is($q->to_string, "or(or(or(#4,#5),#6),#1)", 'Stringification');


# Class
ok($q = $qb->class(
  $qb->term_re('[ac].'),
2), 'Regex in class');
ok($q = $q->normalize->finalize->identify($index->dict)->optimize($index->segment), 'Prepare query');
is($q->to_string, "class(2:or(or(or(#4,#5),#6),#1))", 'Stringification');

# Constraints
ok($q = $qb->constraints(
  [$qb->c_position('precedes')],
  $qb->term_re('[ac].'),
  $qb->term_re('b.')
), 'Regex in constraint');
ok($q = $q->normalize->finalize->identify($index->dict)->optimize($index->segment), 'Prepare query');
is($q->to_string, "constr(pos=1:or(or(or(#4,#5),#6),#1),or(#3,#2))",
   'Stringification');


# Constraints: Inflate in constraint
ok($q = $qb->constraints(
  [
    $qb->c_position('precedes'),
    $qb->c_not_between(
      $qb->term_re('[ac].')
    )
  ],
  $qb->term('aa'),
  $qb->term('bb')
), 'Regex in constraint');
ok($q = $q->normalize->finalize->identify($index->dict), 'Prepare query');
is($q->to_string, "constr(pos=precedes,between=1-1,notBetween=(#1)|(#4)|(#5)|(#6):#1,#2)",
   'Stringification');
ok($q = $q->optimize($index->segment), 'Prepare query');
is($q->to_string, "constr(pos=1,between=1-1,notBetween=or(or(or(#4,#5),#6),#1):#1,#2)",
   'Stringification');

# Constraints: One operand is missing
ok($q = $qb->constraints(
  [
    $qb->c_class_distance(2)
  ],
  $qb->term_re('[ac].'),
  $qb->term_re('b[a]'),
), 'Regex in class');
ok($q = $q->normalize->finalize, 'Prepare query');
is($q->to_string, "constr(class=2:/[ac]./,/b[a]/)", 'Stringification');
ok($q = $q->identify($index->dict), 'Prepare query');
is($q->to_string, "[0]", 'Stringification');
ok($q = $q->optimize($index), 'Prepare query');
is($q->to_string, "[0]", 'Stringification');


# Constraints: One constraint fails
ok($q = $qb->constraints(
  [
    $qb->c_not_between(
      $qb->term_re('[e].')
    )
  ],
  $qb->term_re('[ac].'),
  $qb->term_re('b.'),
), 'Regex in class');
is($q->to_string, "constr(notBetween=/[e]./:/[ac]./,/b./)", 'Stringification');
ok($q = $q->normalize->finalize, 'Prepare query');
is($q->to_string, "constr(pos=precedes;succeeds,between=1-1,notBetween=/[e]./:/[ac]./,/b./)", 'Stringification');
ok($q = $q->identify($index->dict), 'Prepare query');
is($q->to_string,
   "constr(pos=precedes;succeeds,between=1-1,notBetween=[0]:(#1)|(#4)|(#5)|(#6),(#2)|(#3))",
   'Stringification');
ok($q = $q->optimize($index->segment), 'Prepare query');
is($q->to_string,
   "constr(pos=4097,between=1-1:or(or(or(#4,#5),#6),#1),or(#3,#2))",
   'Stringification');



# Sequence
ok($q = $qb->seq(
  $qb->term('aa'),
  $qb->term_re('[ac].'),
), 'Regex in sequence');
ok($q = $q->normalize->finalize->identify($index->dict)->optimize($index->segment), 'Prepare query');
is($q->to_string, "constr(pos=2048:or(or(or(#4,#5),#6),#1),#1)", 'Stringification');



TODO: {
  local $TODO = 'Test with more queries and corpus query';
};


done_testing;

__END__
