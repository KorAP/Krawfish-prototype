use Test::More;
use Test::Krawfish;
use strict;
use warnings;

use_ok('Krawfish::Koral');
use_ok('Krawfish::Index');

my $index = Krawfish::Index->new;

ok_index($index, '<1:opennlp/c=NP>[Der][hey]</1>', 'Add new document');

my $koral = Krawfish::Koral->new;

my $builder = $koral->query_builder;

# Position planning


# isAround(<opennlp/c=NP>, Der)
my $query = $builder->position(
  ['isAround'],
  $builder->span('opennlp/c=NP'),
  $builder->token('Der')
);
ok(!$query->is_any, 'Is any');
ok(!$query->is_optional, 'Isn\'t optional');
ok(!$query->is_null, 'Isn\'t null');
ok(!$query->is_negative, 'Isn\'t negative');
ok(!$query->is_extended, 'Isn\'t extended');
is($query->to_string, 'pos(128:<opennlp/c=NP>,[Der])', 'Stringification');
is($query->prepare_for($index)->to_string, "constr(pos=128:'<>opennlp/c=NP','Der')", 'Planned Stringification');
ok(!$query->has_error, 'Builder has no error');


#####################
# Test 0 as element #
#####################
# isAround(<opennlp/c=NP>,0)
$query = $builder->position(
  ['isAround'],
  $builder->span('opennlp/c=NP'),
  $builder->null
);
ok(!$query->is_any, 'Is any');
ok(!$query->is_optional, 'Isn\'t optional');
ok(!$query->is_null, 'Isn\'t null');
ok(!$query->is_negative, 'Isn\'t negative');
ok(!$query->is_extended, 'Isn\'t extended');
is($query->to_string, 'pos(128:<opennlp/c=NP>,0)', 'Stringification');
is($query->prepare_for($index)->to_string, "'<>opennlp/c=NP'", 'Planned Stringification');
ok(!$query->has_error, 'Builder has no error');

#####################
# Test 0 as element #
#####################
# isAround(<opennlp/c=NP>,0)
$query = $builder->position(
  ['isWithin'],
  $builder->span('opennlp/c=NP'),
  $builder->null
);
ok(!$query->is_any, 'Is any');
ok(!$query->is_optional, 'Isn\'t optional');
ok(!$query->is_null, 'Isn\'t null');
ok(!$query->is_negative, 'Isn\'t negative');
ok(!$query->is_extended, 'Isn\'t extended');
is($query->to_string, 'pos(64:<opennlp/c=NP>,0)', 'Stringification');
ok(!$query->prepare_for($index), 'Planned Stringification');
ok($query->has_error, 'Builder has error');


##########################
# Test freq=0 as element #
##########################
# isAround(<opennlp/c=NP>,Bus)
$query = $builder->position(
  ['isWithin'],
  $builder->span('opennlp/c=NP'),
  $builder->token('Bus')
);
is($query->to_string, 'pos(64:<opennlp/c=NP>,[Bus])', 'Stringification');
is($query->plan_for($index)->to_string, '[0]', 'Planned Stringification');


diag 'Test further';
# extendedLeft, extendedRight, negative, any, optional ...

done_testing;
__END__

