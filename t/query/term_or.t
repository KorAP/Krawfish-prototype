use Test::More;
use strict;
use warnings;
use Data::Dumper;
use File::Basename 'dirname';
use File::Spec::Functions 'catfile';

use_ok('Krawfish::Index');
use_ok('Krawfish::Koral::Query::Builder');

sub cat_t {
  return catfile(dirname(__FILE__), '..', @_);
};

ok(my $qb = Krawfish::Koral::Query::Builder->new, 'Create Koral::Builder');
my $index = Krawfish::Index->new;
ok(defined $index->add(cat_t('data','doc1.jsonld')), 'Add new document');
ok(defined $index->add(cat_t('data','doc2.jsonld')), 'Add new document');
ok(defined $index->add(cat_t('data','doc3-segments.jsonld')), 'Add new document');

my $query = $qb->token(
  $qb->term_or('opennlp/p=V', 'akron=lustigen')
);
is($query->to_string, '[opennlp/p=V|akron=lustigen]', 'termGroup');
ok(my $plan = $query->plan_for($index), 'TermGroup');
is($plan->to_string, "or('opennlp/p=V','akron=lustigen')", 'termGroup');

ok(!$plan->current, 'Not initialized yet');
ok($plan->next, 'Init search');
is($plan->current->to_string, '[2:3-4]', 'Found string');
ok($plan->next, 'More tokens');
is($plan->current->to_string, '[2:5-6]', 'Found string');
ok(!$plan->next, 'No more tokens');

# Todo: Reset index!
$index = Krawfish::Index->new;
ok(defined $index->add(cat_t('data','doc1.jsonld')), 'Add new document');
ok(defined $index->add(cat_t('data','doc2.jsonld')), 'Add new document');
ok(defined $index->add(cat_t('data','doc3-segments.jsonld')), 'Add new document');

$query = $qb->token(
  $qb->term_or('opennlp/p=V', 'akron=lustigen', 'Der')
);
is($query->to_string, '[opennlp/p=V|akron=lustigen|Der]', 'termGroup');
ok($plan = $query->plan_for($index), 'TermGroup');
is($plan->to_string, "or(or('opennlp/p=V','akron=lustigen'),'Der')", 'termGroup');

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



done_testing;

__END__
