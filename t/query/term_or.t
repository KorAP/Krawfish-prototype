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
ok_index_file($index, 'doc1.jsonld', 'Add new document');
ok_index_file($index, 'doc2.jsonld', 'Add new document');
ok_index_file($index, 'doc3-segments.jsonld', 'Add new document');


# (a | b)
my $query = $qb->token(
  $qb->bool_or('opennlp/p=V', 'akron=lustigen')
);
is($query->to_string, '[akron=lustigen|opennlp/p=V]', 'termGroup');
ok($query = $query->normalize, 'Normalization');
is($query->to_string, 'akron=lustigen|opennlp/p=V', 'termGroup');
ok($query = $query->finalize, 'Normalization');
is($query->to_string, 'akron=lustigen|opennlp/p=V', 'termGroup');
ok(my $plan = $query->identify($index->dict)->optimize($index->segment), 'Optimization');
# is($plan->to_string, "or(#66,#70)", 'termGroup');


ok(!$plan->current, 'Not initialized yet');
ok($plan->next, 'Init search');
is($plan->current->to_string, '[2:3-4]', 'Found string');
ok($plan->next, 'More tokens');
is($plan->current->to_string, '[2:5-6]', 'Found string');
ok(!$plan->next, 'No more tokens');


# (a | b | c)
$query = $qb->token(
  $qb->bool_or('opennlp/p=V', 'akron=lustigen', 'Der')
);
is($query->to_string, '[Der|akron=lustigen|opennlp/p=V]', 'termGroup');
ok($query = $query->normalize, 'Normalization');
is($query->to_string, 'Der|akron=lustigen|opennlp/p=V', 'termGroup');
ok($plan = $query->identify($index->dict)->optimize($index->segment), 'Optimization');
# is($plan->to_string, "or(or(#66,#70),#10)", 'termGroup');


ok(!$plan->current, 'Not initialized yet');
ok($plan->next, 'Init search');
is($plan->current->to_string, '[0:0-1]', 'Found string');
ok($plan->next, 'More tokens');
is($plan->current->to_string, '[1:0-1]', 'Found string');
ok($plan->next, 'More tokens');
is($plan->current->to_string, '[2:3-4]', 'Found string');
ok($plan->next, 'More tokens');
is($plan->current->to_string, '[2:5-6]', 'Found string');
ok(!$plan->next, 'No more tokens');


# (a | b | 0)
$query = $qb->token(
  $qb->bool_or('opennlp/p=V', 'traurig', 'Der')
);
is($query->to_string, '[Der|opennlp/p=V|traurig]', 'termGroup');

ok($query = $query->normalize, 'Normalization');
is($query->to_string, 'Der|opennlp/p=V|traurig', 'termGroup');
ok($plan = $query->identify($index->dict)->optimize($index->segment), 'Optimization');
# is($plan->to_string, "or(#66,#10)", 'termGroup');

done_testing;

__END__
