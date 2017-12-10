use Test::More;
use strict;
use warnings;
use Data::Dumper;

use_ok('Krawfish::Koral');

my $koral = Krawfish::Koral->new;

my $qb = $koral->query_builder;

$koral->query(
  $qb->seq(
    $qb->token('Der'),
    $qb->token,
    $qb->span('opennlp/c=NP')
  )
);


is($koral->to_string,
   'query=[[Der][]<opennlp/c=NP>]',
   'Stringification');

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
my $term = $op->[0]->{wrap};
is($term->{'@type'}, 'koral:term', 'Term');
is($term->{'key'}, 'Der', 'Term');

is($op->[1]->{'@type'}, 'koral:token', 'Operand exists');
is($op->[2]->{'@type'}, 'koral:span', 'Operand exists');



# Second test
$koral->query(
  $qb->seq(
    $qb->term('x'),
    $qb->repeat($qb->anywhere, 2,3),
    $qb->token(
      $qb->bool_and(
        'a',
        $qb->bool_or('b','c','d'),
        'e'
      )
    )
  )
);

$serial = $koral->to_koral_query;
ok(!$serial->{corpus}, 'Corpus exists not');
ok(my $query = $serial->{query}, 'Serialization successful');

is($query->{'@type'}, 'koral:group', 'Group');
is($query->{'operation'}, 'operation:sequence', 'operation');
ok($query->{'operands'}, 'operands');

my $ops = $query->{operands};
$op = $ops->[0];

is($op->{'@type'}, 'koral:term', 'Operand is a term');
is($op->{key}, 'x', 'Operand is a term');

$op = $ops->[1];
is($op->{'@type'}, 'koral:group', 'Operand is a group');
is($op->{'operation'}, 'operation:repetition', 'operation');
ok($op->{'operands'}, 'operands');
ok($op->{boundary}, 'Operand has a boundary');

$op = $op->{operands}->[0];
is($op->{'@type'}, 'koral:token', 'Operand is just a token');
is(scalar(keys %{$op}), 1, 'Nothing more');

my $bound = $ops->[1]->{boundary};
is($bound->{'@type'}, 'koral:boundary', 'Boundary type');
is($bound->{'min'}, 2, 'min');
is($bound->{'max'}, 3, 'max');

$op = $ops->[2];
is($op->{'@type'}, 'koral:token', 'Operand is a token');
ok($op->{'wrap'}, 'wrap');

$op = $op->{wrap};
is($op->{'@type'}, 'koral:termGroup', 'Operand is a group');
# is($op->{'operation'}, 'operation:termGroup', 'operation');
# is($op->{'relation'}, 'relation:and', 'operation');
is($op->{'operation'}, 'operation:and', 'operation');
ok($op->{'operands'}, 'operands');

$ops = $op->{operands};
$op = $ops->[0];
is($op->{'@type'}, 'koral:term', 'Operand is a term');
is($op->{key}, 'a', 'Operand is a term');

$op = $ops->[2];
is($op->{'@type'}, 'koral:term', 'Operand is a term');
is($op->{key}, 'e', 'Operand is a term');

$op = $ops->[1];
is($op->{'@type'}, 'koral:termGroup', 'Operand is a group');
# is($op->{'operation'}, 'operation:termGroup', 'operation');
# is($op->{'relation'}, 'relation:or', 'operation');
is($op->{'operation'}, 'operation:or', 'operation');
ok($op->{'operands'}, 'operands');

$ops = $op->{operands};
$op = $ops->[0];
is($op->{'@type'}, 'koral:term', 'Operand is a term');
is($op->{key}, 'b', 'Operand is a term');

$op = $ops->[1];
is($op->{'@type'}, 'koral:term', 'Operand is a term');
is($op->{key}, 'c', 'Operand is a term');

$op = $ops->[2];
is($op->{'@type'}, 'koral:term', 'Operand is a term');
is($op->{key}, 'd', 'Operand is a term');


done_testing;
__END__
