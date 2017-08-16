use Test::More;
use Test::Krawfish;
use strict;
use warnings;


use_ok('Krawfish::Koral');
use_ok('Krawfish::Index');


sub cat_t {
  return catfile(dirname(__FILE__), '..', @_);
};


my $index = Krawfish::Index->new;

ok_index_2($index, [qw/first second third fourth fifth sixth/], 'Add new document');

my $koral = Krawfish::Koral->new;

my $qb = $koral->query_builder;

my $query = $qb->token(
  $qb->bool_and('first', 'second')
);
is($query->min_span, 1, 'Span length');
is($query->max_span, 1, 'Span length');
ok(!$query->is_any, 'Isn\'t any');
ok(!$query->is_optional, 'Isn\'t optional');
ok(!$query->is_null, 'Isn\'t null');
ok(!$query->is_negative, 'Isn\'t negative');
ok(!$query->is_extended, 'Isn\'t extended');
is($query->to_string, '[first&second]', 'Stringification');
is($query->min_span, 1, 'Span length');
is($query->max_span, 1, 'Span length');
ok($query = $query->normalize, 'Normalization');
is($query->to_string, 'first&second', 'Stringification');
ok($query = $query->finalize, 'Finalization');
is($query->to_string, 'first&second', 'Stringification');



$query = $qb->token(
  $qb->bool_and('first', 'second','first', 'third')
);
is($query->min_span, 1, 'Span length');
is($query->max_span, 1, 'Span length');
is($query->to_string, '[first&first&second&third]', 'Stringification');
ok($query = $query->normalize, 'Normalization');
is($query->to_string, 'first&second&third', 'Stringification');
ok($query = $query->finalize, 'Finalization');
is($query->to_string, 'first&second&third', 'Stringification');
is($query->min_span, 1, 'Span length');
is($query->max_span, 1, 'Span length');

$query = $qb->token(
  $qb->bool_and('first', 'second')
);
# The ordering is alphabetically, with the first in order being treated
# like the least common operand, which in a constraint query means,
# it's the second one
is($query->normalize->finalize->identify($index->dict)->optimize($index->segment)->to_string,
   "constr(pos=32:#4,#2)", 'Planned Stringification');


$query = $qb->token(
  $qb->bool_or('opennlp/c=NP', 'tt/p=NN')
);
is($query->min_span, 1, 'Span length');
is($query->max_span, 1, 'Span length');
ok(!$query->is_any, 'Isn\'t any');
ok(!$query->is_optional, 'Isn\'t optional');
ok(!$query->is_null, 'Isn\'t null');
ok(!$query->is_negative, 'Isn\'t negative');
ok(!$query->is_extended, 'Isn\'t extended');
is($query->to_string, '[opennlp/c=NP|tt/p=NN]', 'Stringification');
ok($query = $query->normalize->finalize, 'finalize');
is($query->to_string,
   'opennlp/c=NP|tt/p=NN', 'Stringification');
ok($query = $query->identify($index->dict)->optimize($index->segment), 'finalize');
is($query->to_string,
   '[0]', 'Stringification');


$query = $qb->token(
  $qb->bool_or(
    $qb->bool_and('first', 'second'),
    $qb->bool_and('third', 'fourth'),
  )
);

ok(!$query->is_any, 'Isn\'t any');
ok(!$query->is_optional, 'Isn\'t optional');
ok(!$query->is_null, 'Isn\'t null');
ok(!$query->is_negative, 'Isn\'t negative');
ok(!$query->is_extended, 'Isn\'t extended');
is($query->to_string, '[(first&second)|(fourth&third)]', 'Stringification');
ok($query = $query->normalize, 'Normalize');
is($query->to_string, '(first&second)|(fourth&third)', 'Stringification');
ok($query = $query->finalize->identify($index->dict)->optimize($index->segment), 'Normalize');
is($query->to_string,
   "or(constr(pos=32:#4,#2),constr(pos=32:#8,#6))",
   'Stringification');

is($index->dict->term_by_term_id(6), 'third', 'Check mapping');
is($index->dict->term_by_term_id(8), 'fourth', 'Check mapping');

$query = $qb->token(
  $qb->bool_or(
    $qb->bool_and('first', 'second'),
    $qb->bool_and(
      'third',
      $qb->bool_or('fourth', 'fifth')
    ),
    'sixth'
  )
);


ok(!$query->is_any, 'Isn\'t any');
ok(!$query->is_optional, 'Isn\'t optional');
ok(!$query->is_null, 'Isn\'t null');
ok(!$query->is_negative, 'Isn\'t negative');
ok(!$query->is_extended, 'Isn\'t extended');
is($query->to_string, '[((fifth|fourth)&third)|(first&second)|sixth]', 'Stringification');

ok($query = $query->normalize, 'Normalize');
is($query->to_string, '((fifth|fourth)&third)|(first&second)|sixth', 'Stringification');
ok($query = $query->identify($index->dict)->optimize($index->segment), 'Optimize');
is($query->to_string,
   "or(or(#12,constr(pos=32:#4,#2)),constr(pos=32:or(#10,#8),#6))",
   'Stringification');

# Group with null
$query = $qb->token(
  $qb->bool_and('first', $qb->null)
);
is($query->to_string, '[-&first]', 'Stringifications');
ok($query = $query->normalize, 'Normalize');
is($query->to_string, 'first', 'Stringifications');
ok($query = $query->identify($index->dict)->optimize($index->segment), 'Optimize');
is($query->to_string, "#2", 'Stringifications');


# Group with negation
# [first&!second]
$query = $qb->token(
  $qb->bool_and('first', $qb->term_neg('second'))
);
is($query->to_string, '[!second&first]', 'Stringifications');
ok($query = $query->normalize, 'Normalize');
is($query->to_string, 'excl(32:first,second)', 'Stringifications');
ok($query = $query->identify($index->dict)->optimize($index->segment), 'Optimize');
is($query->to_string, "excl(32:#2,#4)", 'Stringifications');


# Group with negation and zero freq
# [first&opennlp/c!=NN]
$query = $qb->token(
  $qb->bool_and('first', 'opennlp/c!=NN')
);
is($query->to_string, '[first&opennlp/c!=NN]', 'Stringifications');
ok($query = $query->normalize, 'Normalize');
is($query->to_string, 'excl(32:first,opennlp/c=NN)', 'Stringifications');
ok($query = $query->identify($index->dict)->optimize($index->segment), 'Optimize');
is($query->to_string, "#2", 'Stringifications');



# [first&!third&second&!fourth]
$query = $qb->token(
  $qb->bool_and(
    $qb->bool_and('first', $qb->term_neg('third')),
    $qb->bool_and('second', $qb->term_neg('fourth'))
  )
);
is($query->to_string, '[(!fourth&second)&(!third&first)]', 'Stringifications');
ok($query = $query->normalize, 'Normalize');
is($query->to_string, 'excl(32:first&second,fourth|third)', 'Stringifications');
ok($query = $query->identify($index->dict)->optimize($index->segment), 'Optimize');
is($query->to_string, "excl(32:constr(pos=32:#4,#2),or(#6,#8))", 'Stringifications');

# And group with not-founds
# [first&opennlp/c!=NN&second&third&tt/p!=ADJA]
$query = $qb->token(
  $qb->bool_and(
    $qb->bool_and('first', 'opennlp/c!=NN'),
    $qb->bool_and('second', 'tt/p!=ADJA')
  )
);
is($query->to_string, '[(first&opennlp/c!=NN)&(second&tt/p!=ADJA)]', 'Stringifications');
ok($query = $query->normalize->finalize, 'Normalize');
is($query->to_string, 'excl(32:first&second,opennlp/c=NN|tt/p=ADJA)', 'Stringifications');
ok($query = $query->identify($index->dict)->optimize($index->segment), 'Optimize');
is($query->to_string, "constr(pos=32:#4,#2)", 'Stringifications');

done_testing;
__END__
