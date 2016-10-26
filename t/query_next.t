use Test::More;
use strict;
use warnings;
use Data::Dumper;
use File::Basename 'dirname';
use File::Spec::Functions 'catfile';

require '' . catfile(dirname(__FILE__), 'util', 'CreateDoc.pm');

use_ok('Krawfish::Index');
use_ok('Krawfish::QueryBuilder');

my $index = Krawfish::Index->new;

# Der alte Mann ging über die Straße. Er trug einen lustigen Hut
ok($index->add('t/data/doc1.jsonld'), 'Add new document');
# Der Hut stand dem jungen Mann sehr gut. Er betrachtete sich gern im Spiegel.
ok($index->add('t/data/doc2.jsonld'), 'Add new document');

ok(my $qb = Krawfish::QueryBuilder->new($index), 'Create QueryBuilder');

ok(my $seq = $qb->sequence($qb->token('sehr'), $qb->token('gut')), 'Sequence');

ok($seq->next, 'Init');
is($seq->current->to_string, '[1:6-8]', 'Match');
ok(!$seq->next, 'No more');

ok($index->add(simple_doc(qw/aa bb aa bb/)), 'Add new document');

ok($seq = $qb->sequence($qb->token('aa'), $qb->token('bb')), 'Sequence');

ok($seq->next, 'Init');
is($seq->current->to_string, '[2:0-2]', 'Match');

ok($seq->next, 'More');
is($seq->current->to_string, '[2:2-4]', 'Match');
ok(!$seq->next, 'No more');

# Reset index
$index = Krawfish::Index->new;
ok($index->add(complex_doc('[aa|aa][bb|bb]')), 'Add complex document');
ok($qb = Krawfish::QueryBuilder->new($index), 'Create QueryBuilder');
ok($seq = $qb->sequence($qb->token('aa'), $qb->token('bb')), 'Sequence');
ok($seq->next, 'Init');
is($seq->current->to_string, '[0:0-2]', 'Match 1');
ok($seq->next, 'More');
is($seq->current->to_string, '[0:0-2]', 'Match 2');
ok($seq->next, 'More');
is($seq->current->to_string, '[0:0-2]', 'Match 3');
ok($seq->next, 'More');
is($seq->current->to_string, '[0:0-2]', 'Match 4');
ok(!$seq->next, 'No more');

# Reset index
$index = Krawfish::Index->new;
ok($index->add(complex_doc('[aa][bb|bb]')), 'Add complex document');
ok($qb = Krawfish::QueryBuilder->new($index), 'Create QueryBuilder');
ok($seq = $qb->sequence($qb->token('aa'), $qb->token('bb')), 'Sequence');
ok($seq->next, 'Init');
is($seq->current->to_string, '[0:0-2]', 'Match 1');
ok($seq->next, 'More');
is($seq->current->to_string, '[0:0-2]', 'Match 2');
ok(!$seq->next, 'No more');

# Reset index
$index = Krawfish::Index->new;
ok($index->add(complex_doc('[aa|aa][bb]')), 'Add complex document');
ok($qb = Krawfish::QueryBuilder->new($index), 'Create QueryBuilder');
ok($seq = $qb->sequence($qb->token('aa'), $qb->token('bb')), 'Sequence');
ok($seq->next, 'Init');
is($seq->current->to_string, '[0:0-2]', 'Match 1');
ok($seq->next, 'More');
is($seq->current->to_string, '[0:0-2]', 'Match 2');
ok(!$seq->next, 'No more');

print "--------------\n";

# Reset index
$index = Krawfish::Index->new;
ok($index->add(complex_doc('<1:aa><2:aa>[bb]</2>[bb]</1>')), 'Add complex document');
ok($qb = Krawfish::QueryBuilder->new($index), 'Create QueryBuilder');
ok($seq = $qb->sequence($qb->span('aa'), $qb->token('bb')), 'Sequence');
ok($seq->next, 'Init');
is($seq->current->to_string, '[0:0-2]', 'Match 1 <2:aa>[bb]');
#ok($seq->next, 'More');
#is($seq->current->to_string, '[0:0-2]', 'Match 2');
ok(!$seq->next, 'No more');

done_testing;
__END__


