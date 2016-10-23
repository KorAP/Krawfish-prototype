use Test::More;
use strict;
use warnings;
use Data::Dumper;
use File::Basename 'dirname';
use File::Spec::Functions 'catfile';

require '' . catfile(dirname(__FILE__), 'util', 'SimpleDoc.pm');


use_ok('Krawfish::Index');
use_ok('Krawfish::QueryBuilder');

my $index = Krawfish::Index->new('index.dat');

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

print "-----------------------------\n";
ok($seq = $qb->sequence($qb->token('aa'), $qb->token('bb')), 'Sequence');

ok($seq->next, 'Init');
is($seq->current->to_string, '[2:0-2]', 'Match');

ok($seq->next, 'More');
is($seq->current->to_string, '[2:2-4]', 'Match');
ok(!$seq->next, 'No more');


done_testing;
__END__
