use Test::More;
use strict;
use warnings;
use Data::Dumper;

use_ok('Krawfish::Index');
use_ok('Krawfish::Koral::Builder');

# Reset index
my $index = Krawfish::Index->new;
ok(my $qb = Krawfish::Koral::Builder->new($index), 'Create Koral::Builder');
ok(my $seq = $qb->sequence($qb->span('aa'), $qb->token('bb')), 'Sequence');

my $serial = $seq->to_koral_query;

like($serial->{'@context'}, qr!korap\.ids-mannheim\.de!, 'Context is valid');
ok(my $q = $serial->{'query'}, 'Query is given');
is($q->{'@type'}, 'koral:group', '@type is valid');
is($q->{'operation'}, 'operation:position', 'operation is valid');
is($q->{'frames'}->[0], 'frames:precedesDirectly', 'operation is valid');
ok(my $op = $q->{'operands'}, 'Operands exist');
ok($op->[0], 'Operand exists');
ok($op->[1], 'Operand exists');
is($op->[0]->{'@type'}, 'koral:span', 'Operand exists');
is($op->[1]->{'@type'}, 'koral:token', 'Operand exists');

done_testing;
__END__
