use Test::More;
use Test::Krawfish;
use Data::Dumper;
use strict;
use warnings;

my $doc = test_doc([qw/aa bb aa bb/]);

ok(exists $doc->{document}, 'Doc exists');
ok(exists $doc->{document}->{annotations}, 'Annotations exists');
my $anno = $doc->{document}->{annotations};
is($anno->[0]->{'@type'}, 'koral:token', '@type is valid');
is($anno->[0]->{'wrap'}->{'key'}, 'aa', '@type is valid');
is($anno->[-1]->{'@type'}, 'koral:token', '@type is valid');
is($anno->[-1]->{'wrap'}->{'key'}, 'bb', '@type is valid');

ok(my $subtokens = $doc->{document}->{subtokens}, 'Get subtokens');
is_deeply($subtokens->[0]->{offsets}, [0,2], 'Subtoken');
is_deeply($subtokens->[1]->{offsets}, [3,5], 'Subtoken');
is_deeply($subtokens->[2]->{offsets}, [6,8], 'Subtoken');
is_deeply($subtokens->[3]->{offsets}, [9,11], 'Subtoken');
ok(!$subtokens->[4], 'No more subtokens');

is($doc->{document}->{primaryData}, 'aa bb aa bb', 'Primary data');

$doc = test_doc('<1:xy>[aa]<2:opennlp=z>[bb]</1>[corenlp/c=cc|dd]</2>');

ok(exists $doc->{document}, 'Doc exists');

ok(exists $doc->{document}->{annotations}, 'Annotations exists');
$anno = $doc->{document}->{annotations};

is($anno->[0]->{'@type'}, 'koral:token', 'Annotation token');
is($anno->[0]->{'wrap'}->{'key'}, 'aa', 'Annotation key');
is_deeply($anno->[0]->{'subtokens'}, [0], 'Annotation subtokens');

is($anno->[1]->{'@type'}, 'koral:span', 'Annotation span');
is_deeply($anno->[1]->{'subtokens'}, [0,1], 'Annotation subtokens');
is($anno->[1]->{'wrap'}->{'key'}, 'xy', 'Annotation key');

is($anno->[3]->{'@type'}, 'koral:span', 'Annotation token');
is($anno->[3]->{'wrap'}->{'foundry'}, 'opennlp', 'Annotation key');
ok(!exists $anno->[3]->{'wrap'}->{'layer'}, 'Annotation key');
is($anno->[3]->{'wrap'}->{'key'}, 'z', 'Annotation key');

is($anno->[-1]->{'@type'}, 'koral:token', 'Annotation tokenGroup');
ok(exists $anno->[-1]->{'wrap'}, 'Annotation wrap exists');
is($anno->[-1]->{'wrap'}->{'@type'}, 'koral:termGroup', 'Annotation wrap exists');
is_deeply($anno->[-1]->{'subtokens'}, [2], 'Annotation subtokens');

my $token_group = $anno->[-1]->{'wrap'}->{operands};
is($token_group->[0]->{'@type'}, 'koral:term', 'Annotation type');
is($token_group->[0]->{key}, 'cc', 'Annotation key');
is($token_group->[0]->{foundry}, 'corenlp', 'Annotation key');
is($token_group->[0]->{layer}, 'c', 'Annotation key');
is($token_group->[1]->{'@type'}, 'koral:term', 'Annotation type');
is($token_group->[1]->{key}, 'dd', 'Annotation key');

is($doc->{document}->{primaryData}, 'aa bb corenlp/c=cc', 'Check primary data');
ok($subtokens = $doc->{document}->{subtokens}, 'Get subtokens');

is_deeply($subtokens->[0]->{offsets}, [0,2], 'Subtoken');
is_deeply($subtokens->[1]->{offsets}, [3,5], 'Subtoken');
is_deeply($subtokens->[2]->{offsets}, [6,18], 'Subtoken');
ok(!$subtokens->[3], 'No more subtokens');

$doc = test_doc('<1:aa><2:aa>[bb]</2>[bb]</1>');
$anno = $doc->{document}->{annotations};
is($anno->[0]->{'@type'}, 'koral:span', 'Span');
is($anno->[0]->{subtokens}->[0], 0, 'Span');
ok((!$anno->[0]->{subtokens}->[0] || $anno->[0]->{subtokens}->[0] == 0),
    'Span');
is($anno->[2]->{'@type'}, 'koral:span', 'Span');
is($anno->[2]->{subtokens}->[0], 0, 'Span');
is($anno->[2]->{subtokens}->[1], 1, 'Span');


# Docs with meta
$doc = test_doc({id => 5, author => 'Johann Wolfgang von Goethe'} => qw/aa bb aa bb/);
my $fields = $doc->{document}->{fields};
is_deeply($fields->[0], {
  '@type' => 'koral:field',
  'type' => 'type:string',
  'key' => 'author',
  'value' => 'Johann Wolfgang von Goethe'
}, 'First key');

is_deeply($fields->[1], {
  '@type' => 'koral:field',
  'value' => 5,
  'key' => 'id',
  'type' => 'type:string'
}, 'First key');


done_testing;
