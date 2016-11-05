use Test::More;
use strict;
use warnings;
use Data::Dumper;
use File::Basename 'dirname';
use File::Spec::Functions 'catfile';

sub cat_t {
  return catfile(dirname(__FILE__), '..', @_);
};

require '' . cat_t('util', 'CreateDoc.pm');
require '' . cat_t('util', 'TestMatches.pm');

use_ok('Krawfish::Index');
use_ok('Krawfish::Koral::Query::Builder');

my $index = Krawfish::Index->new;

# Der alte Mann ging über die Straße. Er trug einen lustigen Hut
ok(defined $index->add(cat_t('data', 'doc1.jsonld')), 'Add new document');
# Der Hut stand dem jungen Mann sehr gut. Er betrachtete sich gern im Spiegel.
ok(defined $index->add(cat_t('data', 'doc2.jsonld')), 'Add new document');

ok(my $qb = Krawfish::Koral::Query::Builder->new, 'Create Koral::Builder');

ok(my $wrap = $qb->position(
  ['precedesDirectly'],
  $qb->token('sehr'),
  $qb->token('gut')
), 'Sequence');

ok(my $seq = $wrap->plan_for($index), 'Rewrite');

ok($seq->next, 'Init');
is($seq->current->to_string, '[1:6-8]', 'Match');
ok(!$seq->next, 'No more');

ok(defined $index->add(simple_doc(qw/aa bb aa bb/)), 'Add new document');

ok($wrap = $qb->position(['precedesDirectly'], $qb->token('aa'), $qb->token('bb')), 'Sequence');
ok($seq = $wrap->plan_for($index), 'Rewrite');
ok($seq->next, 'Init');
is($seq->current->to_string, '[2:0-2]', 'Match');

ok($seq->next, 'More');
is($seq->current->to_string, '[2:2-4]', 'Match');
ok(!$seq->next, 'No more');

# Reset index - situation [aa]..[bb] -> [aa][bb]
$index = Krawfish::Index->new;
ok(defined $index->add(complex_doc('[aa][cc][aa][bb]')), 'Add complex document');

ok($qb = Krawfish::Koral::Query::Builder->new, 'Create Koral::Builder');

ok($wrap = $qb->position(['precedesDirectly'], $qb->token('aa'), $qb->token('bb')), 'Sequence');
ok($seq = $wrap->plan_for($index), 'Rewrite');

test_matches($seq, qw/[0:2-4]/);

# Reset index - situation [bb][aa] -> [aa][bb]
$index = Krawfish::Index->new;
ok(defined $index->add(complex_doc('[bb][aa][bb][aa]')), 'Add complex document');
ok($qb = Krawfish::Koral::Query::Builder->new, 'Create Koral::Builder');
ok($wrap = $qb->position(['precedesDirectly'], $qb->token('aa'), $qb->token('bb')), 'Sequence');
ok($seq = $wrap->plan_for($index), 'Rewrite');
test_matches($seq, qw/[0:1-3]/);


# Reset index - situation [aa]..[bb] -> [aa][bb]
$index = Krawfish::Index->new;
ok(defined $index->add(complex_doc('[aa][cc][aa][bb]')), 'Add complex document');
ok($qb = Krawfish::Koral::Query::Builder->new, 'Create Koral::Builder');
ok($wrap = $qb->position(['precedesDirectly'],$qb->token('aa'), $qb->token('bb')), 'Sequence');
ok($seq = $wrap->plan_for($index), 'Rewrite');
test_matches($seq, qw/[0:2-4]/);


# Reset index - situation [bb]..[aa] -> [aa][bb]
$index = Krawfish::Index->new;
ok(defined $index->add(complex_doc('[bb][cc][aa][bb]')), 'Add complex document');
ok($qb = Krawfish::Koral::Query::Builder->new($index), 'Create Koral::Builder');
ok($wrap = $qb->position(['precedesDirectly'], $qb->token('aa'), $qb->token('bb')), 'Sequence');
ok($seq = $wrap->plan_for($index), 'Rewrite');
test_matches($seq, qw/[0:2-4]/);


# Multiple matches
# Reset index - situation [bb]..[aa] -> [aa][bb]
$index = Krawfish::Index->new;
ok(defined $index->add(complex_doc('[aa|aa][bb|bb]')), 'Add complex document');
ok($qb = Krawfish::Koral::Query::Builder->new, 'Create Koral::Builder');
ok($wrap = $qb->position(['precedesDirectly'], $qb->token('aa'), $qb->token('bb')), 'Sequence');
ok($seq = $wrap->plan_for($index), 'Rewrite');
test_matches($seq, qw/[0:0-2] [0:0-2] [0:0-2] [0:0-2]/);


# Reset index
$index = Krawfish::Index->new;
ok(defined $index->add(complex_doc('[aa][bb|bb]')), 'Add complex document');
ok($qb = Krawfish::Koral::Query::Builder->new, 'Create Koral::Builder');
ok($wrap = $qb->position(['precedesDirectly'], $qb->token('aa'), $qb->token('bb')), 'Sequence');
ok($seq = $wrap->plan_for($index), 'Rewrite');
# query language: [aa][bb]
test_matches($seq, qw/[0:0-2] [0:0-2]/);

# Reset index
$index = Krawfish::Index->new;
ok(defined $index->add(complex_doc('[aa|aa][bb]')), 'Add complex document');
ok($qb = Krawfish::Koral::Query::Builder->new($index), 'Create Koral::Builder');
ok($wrap = $qb->position(['precedesDirectly'], $qb->token('aa'), $qb->token('bb')), 'Sequence');
ok($seq = $wrap->plan_for($index), 'Rewrite');
test_matches($seq, qw/[0:0-2] [0:0-2]/);


# Reset index
$index = Krawfish::Index->new;
ok(defined $index->add(complex_doc('[aa|aa][bb|bb][aa|aa][bb|bb]')), 'Add complex document');
ok($qb = Krawfish::Koral::Query::Builder->new, 'Create Koral::Builder');
ok($wrap = $qb->position(['precedesDirectly'], $qb->token('aa'), $qb->token('bb')), 'Sequence');
ok($seq = $wrap->plan_for($index), 'Rewrite');
test_matches($seq, qw/[0:0-2] [0:0-2] [0:0-2] [0:0-2] [0:2-4] [0:2-4] [0:2-4] [0:2-4]/);

diag 'Test further';

done_testing;
__END__


# Reset index
$index = Krawfish::Index->new;
ok(defined $index->add(complex_doc('<1:aa><2:aa>[bb]</2>[bb]</1>')), 'Add complex document');
ok($qb = Krawfish::Koral::Query::Builder->new, 'Create Koral::Builder');
ok($wrap = $qb->seq($qb->span('aa'), $qb->token('bb')), 'Sequence');
ok($seq = $wrap->plan_for($index), 'Rewrite');
test_matches($seq, qw/[0:0-2]/);

