use Test::More;
use strict;
use warnings;
use Data::Dumper;

use_ok('Krawfish::Koral');

my $koral = Krawfish::Koral->new;

my $builder = $koral->query_builder;

$koral->query(
  $builder->seq(
    $builder->token('Der'),
    $builder->token,
    $builder->span('opennlp/c=NP')
  )
);

my $serial = $koral->to_koral_query;

like($serial->{'@context'}, qr!korap\.ids-mannheim\.de!, 'Context is valid');
ok(my $q = $serial->{'query'}, 'Query is given');
is($q->{'@type'}, 'koral:group', '@type is valid');
is($q->{'operation'}, 'operation:sequence', 'operation is valid');
ok(my $op = $q->{'operands'}, 'Operands exist');
ok($op->[0], 'Operand exists');
ok($op->[1], 'Operand exists');
ok($op->[2], 'Operand exists');
is($op->[0]->{'@type'}, 'koral:token', 'Operand exists');
is($op->[1]->{'@type'}, 'koral:token', 'Operand exists');
is($op->[2]->{'@type'}, 'koral:span', 'Operand exists');


$builder = $koral->corpus_builder;

done_testing;
__END__
