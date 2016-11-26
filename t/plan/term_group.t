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
is($query->plan_for($index)->to_string, "pos(32:'first','second')", 'Planned Stringification');

$query = $qb->token(
  $qb->term_or('opennlp/c=NP', 'tt/p=NN')
);

ok(!$query->is_any, 'Isn\'t any');
ok(!$query->is_optional, 'Isn\'t optional');
ok(!$query->is_null, 'Isn\'t null');
ok(!$query->is_negative, 'Isn\'t negative');
ok(!$query->is_extended, 'Isn\'t extended');
is($query->to_string, '[opennlp/c=NP|tt/p=NN]', 'Stringification');
is($query->plan_for($index)->to_string, "[0]", 'Planned Stringification');

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
is($query->plan_for($index)->to_string,
   "or(pos(32:'first','second'),pos(32:'third','fourth'))",
   'Planned Stringification');

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
is($query->plan_for($index)->to_string,
   "or(or(pos(32:'first','second'),pos(32:'third',or('fourth','fifth'))),'sixth')",
   'Planned Stringification');

# Group with null
$query = $qb->token(
  $qb->term_and('first', $qb->null)
);
is($query->to_string, '[first&0]', 'Stringifications');
is($query->plan_for($index)->to_string,
   "'first'",
   'Planned stringification');

# Group with negation
# [first&!second]
$query = $qb->token(
  $qb->term_and('first', $qb->term_neg('second'))
);
is($query->to_string, '[first&!second]', 'Stringifications');
is($query->plan_for($index)->to_string,
   "excl(32:'first','second')",
   'Planned Stringification');

# Group with negation and zero freq
# [first&opennlp/c!=NN]
$query = $qb->token(
  $qb->term_and('first', 'opennlp/c!=NN')
);
is($query->to_string, '[first&opennlp/c!=NN]', 'Stringifications');
is($query->plan_for($index)->to_string,
   "'first'",
   'Planned Stringification');

# [first&!third&second&!fourth]
$query = $qb->token(
  $qb->term_and(
    $qb->term_and('first', $qb->term_neg('third')),
    $qb->term_and('second', $qb->term_neg('fourth'))
  )
);
is($query->to_string, '[(first&!third)&(second&!fourth)]', 'Stringifications');
is($query->plan_for($index)->to_string,
   "excl(32:pos(32:'first','second'),or('third','fourth'))",
   'Planned Stringification');

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
   "pos(32:'first','second')",
   'Planned Stringification');

done_testing;
__END__


done_testing;
__END__

