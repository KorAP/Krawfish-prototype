use Test::More;
use Test::Krawfish;
use strict;
use warnings;

use_ok('Krawfish::Koral');
use_ok('Krawfish::Index');

my $index = Krawfish::Index->new;

ok_index_2($index, '<1:opennlp/c=NP>[Der][hey]</1>', 'Add new document');

my $koral = Krawfish::Koral->new;

my $builder = $koral->query_builder;

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
is($query->to_string, 'constr(pos=isAround:<opennlp/c=NP>,[Der])', 'Stringification');
ok($query = $query->normalize, 'Normalize');
is($query->to_string, 'constr(pos=isAround:<opennlp/c=NP>,Der)', 'Stringification');
ok(!$query->has_error, 'Builder has no error');
ok($query = $query->identify($index->dict), 'Optimize');
is($query->to_string, "constr(pos=isAround:#3,#2)", 'Stringification');
ok($query = $query->optimize($index->segment), 'Optimize');
is($query->to_string, "constr(pos=128:#3,#2)", 'Stringification');



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
is($query->to_string, 'constr(pos=isAround:<opennlp/c=NP>,-)', 'Stringification');
ok($query = $query->normalize, 'Normalize');
ok(!$query->has_error, 'Builder has no error');
is($query->to_string, '<opennlp/c=NP>', 'Stringification');
ok($query = $query->identify($index->dict)->optimize($index->segment), 'Optimize');
is($query->to_string, "#3", 'Planned Stringification');


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
is($query->to_string, 'constr(pos=isWithin:<opennlp/c=NP>,-)', 'Stringification');
ok(!$query->normalize, 'Normalize');
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
is($query->to_string, 'constr(pos=isWithin:<opennlp/c=NP>,[Bus])', 'Stringification');
ok($query = $query->normalize, 'Normalize');
is($query->to_string, 'constr(pos=isWithin:<opennlp/c=NP>,Bus)', 'Stringification');
ok($query = $query->identify($index->dict)->optimize($index->segment), 'Normalize');
is($query->to_string, '[0]', 'Stringification');


TODO: {
  local $TODO = "Test further";
  # extendedLeft, extendedRight, negative, any, optional ...
};


done_testing;
__END__

