use Test::More;
use strict;
use warnings;
use Data::Dumper;

use_ok('Krawfish::Koral');

my $koral = Krawfish::Koral->new;

my $cb = $koral->corpus_builder;

$koral->corpus(
  $cb->field_or(
    $cb->date('pub_date')->geq('2015-03'),
    $cb->field_and(
      $cb->string('author')->eq('Nils'),
      $cb->regex('doc_id')->eq('WPD.*')
    )
  )
);

my $serial = $koral->to_koral_query;
ok($serial->{corpus}, 'Corpus exists');
my $corpus = $serial->{corpus};
is($corpus->{'@type'}, 'koral:fieldGroup', 'fieldGroup');
is($corpus->{'operation'}, 'operation:or', 'operation');
ok($corpus->{'operands'}, 'operands');
my $operands = $corpus->{operands};

is($operands->[0]->{'@type'}, 'koral:field', 'Operand is a field');
is($operands->[0]->{key}, 'pub_date', 'Operand is a field');
is($operands->[0]->{value}, '2015-03', 'Operand is a field');
is($operands->[0]->{type}, 'type:date', 'Operand is a field');
is($operands->[0]->{match}, 'match:geq', 'Operand is a field');

is($operands->[1]->{'@type'}, 'koral:fieldGroup', 'Operand is a field');

done_testing;

__END__
