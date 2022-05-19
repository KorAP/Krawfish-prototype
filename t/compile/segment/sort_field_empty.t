use Test::More;
use Test::Krawfish;
use Data::Dumper;
use strict;
use warnings;

use_ok('Krawfish::Index');
use_ok('Krawfish::Koral');

# Create some documents
my $index = Krawfish::Index->new;

ok($index->introduce_field('id', 'NUM'), 'Introduce field as sortable');
ok($index->introduce_field('author', 'DE'), 'Introduce field as sortable');
ok($index->introduce_field('age', 'NUM'), 'Introduce field as sortable');

ok_index($index, {
  id => 2,
  age => 4,
  author => 'Peter',
} => [qw/aa/], 'Add complex document');
ok_index($index, {
  id => 3,
  age => 4,
  author => 'Julian',
} => [qw/aa/], 'Add complex document');
ok_index($index, {
  age => 4,
  id => 1,
} => [qw/aa/], 'Add complex document');

ok($index->commit, 'Commit data');

my $koral = Krawfish::Koral->new;
my $qb = $koral->query_builder;
my $mb = $koral->compilation_builder;
my ($query, $result, $clone);

# Sort with an empty field
$koral = Krawfish::Koral->new;
$koral->query($qb->token('aa'));
$koral->compilation(
  $mb->sort_by($mb->s_field('author')),
);
ok($query = $koral->to_query->identify($index->dict)->optimize($index->segment), 'Optimize');
is($query->to_string,
   'sort(field=#1<,l=1:sort(field=#2<:bundleDocs(filter(#8,[1]))))',
   'Stringification');
ok($result = $query->compile->inflate($index->dict), 'Run clone');
is($result->to_string,
   '[matches=[1:0-1::IKs..gAA,3][0:0-1::IWs..gAA,2][2:0-1::-,1]]',
   'Stringification');

# Sort in reverse order with an empty field
$koral = Krawfish::Koral->new;
$koral->query($qb->token('aa'));
$koral->compilation(
  $mb->sort_by($mb->s_field('author', 1)),
);
ok($query = $koral->to_query, 'To query');
is($query->to_string,
   "sort(field='id'<:sort(field='author'>:filter(aa,[1])))",
   'Stringification');
ok($query = $query->identify($index->dict), 'Identify');
is($query->to_string(1),
   'sort(field=#1<:sort(field=#2>:filter(#8,[1])))',
   'Stringification');
ok($query = $query->optimize($index->segment), 'Optimize');
is($query->to_string(1),
   'sort(field=#1<,l=1:sort(field=#2>:bundleDocs(filter(#8,[1]))))',
   'Stringification');
ok($result = $query->compile->inflate($index->dict), 'Run clone');
is($result->to_string,
   '[matches=[0:0-1::IWs..gAA,2][1:0-1::IKs..gAA,3][2:0-1::-,1]]',
   'Stringification');

# Sort after with an empty field
$koral = Krawfish::Koral->new;
$koral->query($qb->token('aa'));
$koral->compilation(
  $mb->sort_by($mb->s_field('age')),
  $mb->sort_by($mb->s_field('author'))
);
ok($query = $koral->to_query->identify($index->dict)->optimize($index->segment), 'Optimize');
is($query->to_string,
   'sort(field=#1<,l=2:sort(field=#2<,l=1:sort(field=#3<:bundleDocs(filter(#8,[1])))))',
   'Stringification');

ok($clone = $query->clone, 'Clone query');

ok($query->next_bundle, 'Next');
is($query->current_bundle->to_string, '[[[1:0-1]::1,1]]', 'Stringification');
ok($query->next_bundle, 'Next');
is($query->current_bundle->to_string, '[[[0:0-1]::1,2]]', 'Stringification');
ok($query->next_bundle, 'Next');
is($query->current_bundle->to_string, '[[[2:0-1]::1,3]]', 'Stringification');
ok(!$query->next_bundle, 'Next');

ok($result = $clone->compile->inflate($index->dict), 'Run clone');
is($result->to_string,
   '[matches=[1:0-1::4,IKs..gAA,3][0:0-1::4,IWs..gAA,2][2:0-1::4,-,1]]',
   'Stringification');

# Sort after in reverse order with an empty field
$koral = Krawfish::Koral->new;
$koral->query($qb->token('aa'));
$koral->compilation(
  $mb->sort_by($mb->s_field('age')),
  $mb->sort_by($mb->s_field('author', 1))
);
ok($query = $koral->to_query->identify($index->dict)->optimize($index->segment), 'Optimize');
is($query->to_string,
   'sort(field=#1<,l=2:sort(field=#2>,l=1:sort(field=#3<:bundleDocs(filter(#8,[1])))))',
   'Stringification');
ok($result = $query->compile->inflate($index->dict), 'Run clone');
is($result->to_string,
   '[matches=[0:0-1::4,IWs..gAA,2][1:0-1::4,IKs..gAA,3][2:0-1::4,-,1]]',
   'Stringification');


done_testing;
__END__
