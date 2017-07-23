use Test::More;
use strict;
use warnings;
use Data::Dumper;

use_ok('Krawfish::Koral');

my $koral = Krawfish::Koral->new;

my $qb = $koral->query_builder;

$koral->query(
  $qb->seq(
    $qb->term('x'),
    $qb->repeat($qb->any, 2,3),
    $qb->token(
      $qb->bool_and(
        'a',
        $qb->bool_or('b','c','d'),
        'e'
      )
    )
  )
);

my $serial = $koral->to_koral_query;
ok(!$serial->{corpus}, 'Corpus exists not');
ok(my $query = $serial->{query}, 'Serialization successful');

is($query->{'@type'}, 'koral:group', 'Group');
is($query->{'operation'}, 'operation:sequence', 'operation');
ok($query->{'operands'}, 'operands');

my $ops = $query->{operands};
my $op = $ops->[0];

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
is($op->{'@type'}, 'koral:group', 'Operand is a group');
is($op->{'operation'}, 'operation:termGroup', 'operation');
is($op->{'relation'}, 'relation:and', 'operation');
ok($op->{'operands'}, 'operands');

$ops = $op->{operands};
$op = $ops->[0];
is($op->{'@type'}, 'koral:term', 'Operand is a term');
is($op->{key}, 'a', 'Operand is a term');

$op = $ops->[2];
is($op->{'@type'}, 'koral:term', 'Operand is a term');
is($op->{key}, 'e', 'Operand is a term');

$op = $ops->[1];
is($op->{'@type'}, 'koral:group', 'Operand is a group');
is($op->{'operation'}, 'operation:termGroup', 'operation');
is($op->{'relation'}, 'relation:or', 'operation');
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


TODO: {
  local $TODO = 'Test Serialization output';
  ok($koral = $koral->normalize->finalize, 'Finalize query');
};


done_testing;
__END__

