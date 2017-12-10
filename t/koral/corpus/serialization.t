use Test::More;
use strict;
use warnings;
use Data::Dumper;

use_ok('Krawfish::Koral');

my $koral = Krawfish::Koral->new;

# Create corpus
my $cb = $koral->corpus_builder;

my $corpus_query = $cb->bool_and(
  $cb->string('author')->eq('Peter'),
  $cb->date('pubDate')->geq('2014-04-03')
);

is($corpus_query->to_string, 'author=Peter&pubDate>=2014-04-03',
   'Stringification of corpus query');

$koral->corpus($corpus_query);

is($koral->to_string,
   'corpus=[author=Peter&pubDate>=2014-04-03]',
   'Stringification');

my $serial = $koral->to_koral_query;

ok(my $c = $serial->{'corpus'}, 'Query is given');
is($c->{'@type'}, 'koral:fieldGroup', '@type');
is($c->{'operation'}, 'operation:and', 'operation');
ok(my $op = $c->{'operands'}, 'Operands');

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
