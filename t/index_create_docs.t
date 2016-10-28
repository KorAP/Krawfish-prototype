use Test::More;
use strict;
use warnings;
use Data::Dumper;
use File::Basename 'dirname';
use File::Spec::Functions 'catfile';

require '' . catfile(dirname(__FILE__), 'util', 'CreateDoc.pm');

my $doc = simple_doc(qw/aa bb aa bb/);
ok(exists $doc->{text}, 'Doc exists');
ok(exists $doc->{text}->{annotation}, 'Annotations exists');
my $anno = $doc->{text}->{annotation};
is($anno->[0]->{'@type'}, 'koral:token', '@type is valid');
is($anno->[0]->{'key'}, 'aa', '@type is valid');
is($anno->[-1]->{'@type'}, 'koral:token', '@type is valid');
is($anno->[-1]->{'key'}, 'bb', '@type is valid');


$doc = complex_doc('<1:xy>[aa]<2:opennlp=z>[bb]</1>[corenlp/c=cc|dd]</2>');
ok(exists $doc->{text}, 'Doc exists');
ok(exists $doc->{text}->{annotation}, 'Annotations exists');
$anno = $doc->{text}->{annotation};

is($anno->[0]->{'@type'}, 'koral:token', 'Annotation token');
is($anno->[0]->{'key'}, 'aa', 'Annotation key');
is_deeply($anno->[0]->{'segments'}, [0], 'Annotation segments');

is($anno->[1]->{'@type'}, 'koral:span', 'Annotation span');
is_deeply($anno->[1]->{'segments'}, [0,1], 'Annotation segments');
is($anno->[1]->{'key'}, 'xy', 'Annotation key');



is($anno->[3]->{'@type'}, 'koral:span', 'Annotation token');
is($anno->[3]->{'foundry'}, 'opennlp', 'Annotation key');
ok(!exists $anno->[3]->{'layer'}, 'Annotation key');
is($anno->[3]->{'key'}, 'z', 'Annotation key');


is($anno->[-1]->{'@type'}, 'koral:tokenGroup', 'Annotation tokenGroup');
ok(exists $anno->[-1]->{'wrap'}, 'Annotation wrap exists');
is_deeply($anno->[-1]->{'segments'}, [2], 'Annotation segments');

my $token_group = $anno->[-1]->{'wrap'};
is($token_group->[0]->{'@type'}, 'koral:token', 'Annotation type');
is($token_group->[0]->{key}, 'cc', 'Annotation key');
is($token_group->[0]->{foundry}, 'corenlp', 'Annotation key');
is($token_group->[0]->{layer}, 'c', 'Annotation key');
is($token_group->[1]->{'@type'}, 'koral:token', 'Annotation type');
is($token_group->[1]->{key}, 'dd', 'Annotation key');

$doc = complex_doc('<1:aa><2:aa>[bb]</2>[bb]</1>');
$anno = $doc->{text}->{annotation};
is($anno->[0]->{'@type'}, 'koral:span', 'Span');
is($anno->[0]->{segments}->[0], 0, 'Span');
ok((!$anno->[0]->{segments}->[0] || $anno->[0]->{segments}->[0] == 0),
    'Span');
is($anno->[2]->{'@type'}, 'koral:span', 'Span');
is($anno->[2]->{segments}->[0], 0, 'Span');
is($anno->[2]->{segments}->[1], 1, 'Span');

done_testing;
