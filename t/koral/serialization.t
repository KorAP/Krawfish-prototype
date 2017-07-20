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

is($koral->to_string,
   '[Der][]<opennlp/c=NP>',
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


# Create corpus
$builder = $koral->corpus_builder;

my $corpus_query = $builder->field_and(
  $builder->string('author')->eq('Peter'),
  $builder->date('pubDate')->geq('2014-04-03')
);

is($corpus_query->to_string, 'author=Peter&pubDate>=2014-04-03',
   'Stringification of corpus query');

$koral->corpus($corpus_query);

is($koral->to_string,
   'filter([Der][]<opennlp/c=NP>,author=Peter&pubDate>=2014-04-03)', 'Stringification');

$serial = $koral->to_koral_query;

ok(my $c = $serial->{'corpus'}, 'Query is given');
is($c->{'@type'}, 'koral:fieldGroup', '@type');
is($c->{'operation'}, 'operation:and', 'operation');
ok($op = $c->{'operands'}, 'Operands');

is($op->[0]->{'@type'}, 'koral:field', 'Operand');
is($op->[0]->{'type'}, 'type:string', 'Operand');
is($op->[0]->{'key'}, 'author', 'Operand');
is($op->[0]->{'value'}, 'Peter', 'Operand');
is($op->[0]->{'match'}, 'match:eq', 'Operand');

is($op->[1]->{'@type'}, 'koral:field', 'Operand');
is($op->[1]->{'type'}, 'type:date', 'Operand');
is($op->[1]->{'key'}, 'pubDate', 'Operand');
is($op->[1]->{'value'}, '2014-04-03', 'Operand');
is($op->[1]->{'match'}, 'match:geq', 'Operand');

done_testing;
__END__
