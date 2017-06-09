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

ok_index($index, [qw/first second third fourth fifth sixth/], 'Add new document');

my $koral = Krawfish::Koral->new;

my $qb = $koral->query_builder;

my $query = $qb->token(
  $qb->term_and('first', 'second')
);

ok(!$query->is_any, 'Isn\'t any');
ok(!$query->is_optional, 'Isn\'t optional');
ok(!$query->is_null, 'Isn\'t null');
ok(!$query->is_negative, 'Isn\'t negative');
ok(!$query->is_extended, 'Isn\'t extended');
is($query->to_string, '[first&second]', 'Stringification');

ok($query = $query->normalize, 'Normalization');
is($query->to_string, '[first&second]', 'Stringification');
ok($query = $query->finalize, 'Finalization');
is($query->to_string, '[first&second]', 'Stringification');


$query = $qb->token(
  $qb->term_and('first', 'second','first', 'third')
);
is($query->to_string, '[first&second&first&third]', 'Stringification');
ok($query = $query->normalize, 'Normalization');
is($query->to_string, '[first&second&third]', 'Stringification');
ok($query = $query->finalize, 'Finalization');
is($query->to_string, '[first&second&third]', 'Stringification');


$query = $qb->token(
  $qb->term_and('first', 'second')
);

is($query->normalize->finalize->optimize($index)->to_string,
   "constr(pos=32:'first','second')", 'Planned Stringification');

$query = $qb->token(
  $qb->term_or('opennlp/c=NP', 'tt/p=NN')
);

ok(!$query->is_any, 'Isn\'t any');
ok(!$query->is_optional, 'Isn\'t optional');
ok(!$query->is_null, 'Isn\'t null');
ok(!$query->is_negative, 'Isn\'t negative');
ok(!$query->is_extended, 'Isn\'t extended');
is($query->to_string, '[opennlp/c=NP|tt/p=NN]', 'Stringification');
ok($query = $query->normalize->finalize, 'finalize');
is($query->to_string,
   '[opennlp/c=NP|tt/p=NN]', 'Stringification');
ok($query = $query->optimize($index), 'finalize');
is($query->to_string,
   '[0]', 'Stringification');


$query = $qb->token(
  $qb->term_or(
    $qb->term_and('first', 'second'),
    $qb->term_and('third', 'fourth'),
  )
);

ok(!$query->is_any, 'Isn\'t any');
ok(!$query->is_optional, 'Isn\'t optional');
ok(!$query->is_null, 'Isn\'t null');
ok(!$query->is_negative, 'Isn\'t negative');
ok(!$query->is_extended, 'Isn\'t extended');
is($query->to_string, '[(first&second)|(third&fourth)]', 'Stringification');
ok($query = $query->normalize, 'Normalize');
is($query->to_string, '[(first&second)|(fourth&third)]', 'Stringification');
ok($query = $query->finalize->optimize($index), 'Normalize');
is($query->to_string,
   "or(constr(pos=32:'first','second'),constr(pos=32:'fourth','third'))",
 'Stringification');

$query = $qb->token(
  $qb->term_or(
    $qb->term_and('first', 'second'),
    $qb->term_and(
      'third',
      $qb->term_or('fourth', 'fifth')
    ),
    'sixth'
  )
);

ok(!$query->is_any, 'Isn\'t any');
ok(!$query->is_optional, 'Isn\'t optional');
ok(!$query->is_null, 'Isn\'t null');
ok(!$query->is_negative, 'Isn\'t negative');
ok(!$query->is_extended, 'Isn\'t extended');
is($query->to_string, '[(first&second)|(third&(fourth|fifth))|sixth]', 'Stringification');
ok($query = $query->normalize, 'Normalize');
is($query->to_string, '[((fifth|fourth)&third)|(first&second)|sixth]', 'Stringification');
ok($query = $query->optimize($index), 'Optimize');
is($query->to_string,
   "or(or(constr(pos=32:or('fifth','fourth'),'third'),constr(pos=32:'first','second')),'sixth')",
   'Stringification');


# Group with null
$query = $qb->token(
  $qb->term_and('first', $qb->null)
);
is($query->to_string, '[first&0]', 'Stringifications');
ok($query = $query->normalize, 'Normalize');
is($query->to_string, '[first]', 'Stringifications');
ok($query = $query->optimize($index), 'Optimize');
is($query->to_string, "'first'", 'Stringifications');

# Group with negation
# [first&!second]
$query = $qb->token(
  $qb->term_and('first', $qb->term_neg('second'))
);
is($query->to_string, '[first&!second]', 'Stringifications');
ok($query = $query->normalize, 'Normalize');
is($query->to_string, '[excl(32:first,second)]', 'Stringifications');
ok($query = $query->optimize($index), 'Optimize');
is($query->to_string, "excl(32:'first','second')", 'Stringifications');

# Group with negation and zero freq
# [first&opennlp/c!=NN]
$query = $qb->token(
  $qb->term_and('first', 'opennlp/c!=NN')
);
is($query->to_string, '[first&opennlp/c!=NN]', 'Stringifications');
ok($query = $query->normalize, 'Normalize');
is($query->to_string, '[excl(32:first,opennlp/c=NN)]', 'Stringifications');
ok($query = $query->optimize($index), 'Optimize');
is($query->to_string, "'first'", 'Stringifications');



# [first&!third&second&!fourth]
$query = $qb->token(
  $qb->term_and(
    $qb->term_and('first', $qb->term_neg('third')),
    $qb->term_and('second', $qb->term_neg('fourth'))
  )
);
is($query->to_string, '[(first&!third)&(second&!fourth)]', 'Stringifications');
ok($query = $query->normalize, 'Normalize');
is($query->to_string, '[excl(32:first&second,third|fourth)]', 'Stringifications');
ok($query = $query->optimize($index), 'Optimize');
is($query->to_string, "excl(32:constr(pos=32:'first','second'),or('fourth','third'))", 'Stringifications');



# And group with not-founds
# [first&opennlp/c!=NN&second&third&tt/p!=ADJA]
$query = $qb->token(
  $qb->term_and(
    $qb->term_and('first', 'opennlp/c!=NN'),
    $qb->term_and('second', 'tt/p!=ADJA')
  )
);
is($query->to_string, '[(first&opennlp/c!=NN)&(second&tt/p!=ADJA)]', 'Stringifications');
is($query->plan_for($index)->to_string,
   "constr(pos=32:'first','second')",
   'Planned Stringification');

done_testing;
__END__
