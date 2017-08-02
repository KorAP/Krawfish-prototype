use Test::More;
use Test::Krawfish;
use strict;
use warnings;

use_ok('Krawfish::Index');
use_ok('Krawfish::Koral::Query::Builder');

my $index = Krawfish::Index->new;

# Der alte Mann ging über die Straße. Er trug einen lustigen Hut
ok(defined $index->add(test_file('doc1.jsonld')), 'Add new document');
# Der Hut stand dem jungen Mann sehr gut. Er betrachtete sich gern im Spiegel.
ok(defined $index->add(test_file('doc2.jsonld')), 'Add new document');

ok(my $qb = Krawfish::Koral::Query::Builder->new, 'Create QueryBuilder');

ok(my $wrap = $qb->seq($qb->token('sehr'), $qb->token('gut')), 'Seq');
ok(my $seq = $wrap->normalize->finalize->identify($index->dict)->optimize($index->segment), 'Rewrite');

ok($seq->next, 'More');
is($seq->current->to_string, '[1:6-8]', 'Match');
ok(!$seq->next, 'No more');

ok_index($index, [qw/aa bb aa bb/], 'Add new document');

ok($wrap = $qb->seq($qb->token('aa'), $qb->token('bb')), 'Seq');
ok($seq = $wrap->normalize->finalize->identify($index->dict)->optimize($index->segment), 'Rewrite');

ok($seq->next, 'Init');
is($seq->current->to_string, '[2:0-2]', 'Match');
ok($seq->next, 'More');
is($seq->current->to_string, '[2:2-4]', 'Match');
ok(!$seq->next, 'No more');

# Reset index - situation [aa]..[bb] -> [aa][bb]
$index = Krawfish::Index->new;
ok_index($index, '[aa][cc][aa][bb]', 'Add complex document');
ok($qb = Krawfish::Koral::Query::Builder->new, 'Create QueryBuilder');
ok($wrap = $qb->seq($qb->token('aa'), $qb->token('bb')), 'Seq');
ok($seq = $wrap->normalize->finalize->identify($index->dict)->optimize($index->segment), 'Rewrite');
matches($seq, [qw/[0:2-4]/]);

# Reset index - situation [bb][aa] -> [aa][bb]
$index = Krawfish::Index->new;
ok_index($index, '[bb][aa][bb][aa]', 'Add complex document');
ok($qb = Krawfish::Koral::Query::Builder->new, 'Create QueryBuilder');
ok($wrap = $qb->seq($qb->token('aa'), $qb->token('bb')), 'Seq');
ok($seq = $wrap->normalize->finalize->identify($index->dict)->optimize($index->segment), 'Rewrite');
matches($seq, [qw/[0:1-3]/]);


# Reset index - situation [aa]..[bb] -> [aa][bb]
$index = Krawfish::Index->new;
ok_index($index, '[aa][cc][aa][bb]', 'Add complex document');
ok($qb = Krawfish::Koral::Query::Builder->new, 'Create QueryBuilder');
ok($wrap = $qb->seq($qb->token('aa'), $qb->token('bb')), 'Seq');
ok($seq = $wrap->normalize->finalize->identify($index->dict)->optimize($index->segment), 'Rewrite');
matches($seq, [qw/[0:2-4]/]);


# Reset index - situation [bb]..[aa] -> [aa][bb]
$index = Krawfish::Index->new;
ok_index($index, '[bb][cc][aa][bb]', 'Add complex document');
ok($qb = Krawfish::Koral::Query::Builder->new, 'Create QueryBuilder');
ok($wrap = $qb->seq($qb->token('aa'), $qb->token('bb')), 'Seq');
ok($seq = $wrap->normalize->finalize->identify($index->dict)->optimize($index->segment), 'Rewrite');
matches($seq, [qw/[0:2-4]/]);


# Multiple matches
# Reset index
$index = Krawfish::Index->new;
ok_index($index, '[aa|aa][bb|bb]', 'Add complex document');
ok($qb = Krawfish::Koral::Query::Builder->new, 'Create QueryBuilder');
ok($wrap = $qb->seq($qb->token('aa'), $qb->token('bb')), 'Seq');
ok($seq = $wrap->normalize->finalize->identify($index->dict)->optimize($index->segment), 'Rewrite');
matches($seq, [qw/[0:0-2] [0:0-2] [0:0-2] [0:0-2]/]);


# Reset index
$index = Krawfish::Index->new;
ok_index($index, '[aa][bb|bb]', 'Add complex document');
ok($qb = Krawfish::Koral::Query::Builder->new, 'Create QueryBuilder');
ok($wrap = $qb->seq($qb->token('aa'), $qb->token('bb')), 'Seq');
ok($seq = $wrap->normalize->finalize->identify($index->dict)->optimize($index->segment), 'Rewrite');
# query language: [aa][bb]
matches($seq, [qw/[0:0-2] [0:0-2]/]);


# Reset index
$index = Krawfish::Index->new;
ok_index($index, '[aa|aa][bb]', 'Add complex document');
ok($qb = Krawfish::Koral::Query::Builder->new, 'Create QueryBuilder');
ok($wrap = $qb->seq($qb->token('aa'), $qb->token('bb')), 'Seq');
ok($seq = $wrap->normalize->finalize->identify($index->dict)->optimize($index->segment), 'Rewrite');
matches($seq, [qw/[0:0-2] [0:0-2]/]);


# Reset index
$index = Krawfish::Index->new;
ok_index($index, '[aa|aa][bb|bb][aa|aa][bb|bb]', 'Add complex document');
ok($qb = Krawfish::Koral::Query::Builder->new, 'Create QueryBuilder');
ok($wrap = $qb->seq($qb->token('aa'), $qb->token('bb')), 'Seq');
ok($seq = $wrap->normalize->finalize->identify($index->dict)->optimize($index->segment), 'Rewrite');
matches($seq, [qw/[0:0-2] [0:0-2] [0:0-2] [0:0-2] [0:2-4] [0:2-4] [0:2-4] [0:2-4]/]);


# Reset index
$index = Krawfish::Index->new;
ok_index($index, '<1:aa><2:aa>[bb]</2>[bb]</1>', 'Add complex document');
ok($qb = Krawfish::Koral::Query::Builder->new, 'Create QueryBuilder');
ok($wrap = $qb->seq($qb->span('aa'), $qb->token('bb')), 'Seq');
is($wrap->to_string, '<aa>[bb]', 'Stringification');
ok($seq = $wrap->normalize->finalize->identify($index->dict)->optimize($index->segment), 'Rewrite');
matches($seq, [qw/[0:0-2]/]);



done_testing;
__END__


