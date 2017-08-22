use Test::More;
use Test::Krawfish;
use strict;
use warnings;

use_ok('Krawfish::Index');
use_ok('Krawfish::Koral');

my $index = Krawfish::Index->new;
ok_index($index, {
  id => 'doc-1',
  license => 'free',
  corpus => 'corpus-2'
} => [qw/aa bb/], 'Add new document');

ok_index($index, {
  id => 'doc-2',
  license => 'closed',
  corpus => 'corpus-3'
} => [qw/aa bb/], 'Add new document');
ok_index($index, {
  id => 'doc-3',
  license => 'free',
  corpus => 'corpus-1',
  store_uri => 'My URL'
} => [qw/bb cc/], 'Add new document');


my $koral = Krawfish::Koral->new;
my $qb = $koral->query_builder;
my $mb = $koral->meta_builder;

$koral->query($qb->token('aa'));

$koral->meta(
  $mb->group_by(
    $mb->g_fields('license','corpus')
  )
);

is($koral->to_string,
   "meta=[group=[fields:['license','corpus']]],query=[[aa]]",
   'Stringification');

ok(my $koral_query = $koral->to_query, 'Normalization');

# This is a query that is fine to be send to segments:
ok($koral_query = $koral_query->identify($index->dict), 'Identify');

# This is a query that is fine to be send to nodes
is($koral_query->to_string,
   "gFields(#1,#5:filter(#8,[1]))",
   'Stringification');


done_testing;
__END__

use Test::More;
use Test::Krawfish;
use Data::Dumper;
use strict;
use warnings;

use_ok('Krawfish::Index');
use_ok('Krawfish::Koral::Query::Builder');
use_ok('Krawfish::Result::Group');
use_ok('Krawfish::Result::Group::Classes');

my $index = Krawfish::Index->new;

ok_index_file($index, 'doc3-segments.jsonld', 'Add new document');

my $kq = Krawfish::Koral::Query::Builder->new;

# Simple query
my $query = $kq->token('akron=Bau-Leiter');

is($query->to_string, '[akron=Bau-Leiter]', 'Stringification');




diag 'Check groups without subtoken index';



done_testing;
__END__


# Create class criterion
my $criterion = Krawfish::Result::Group::Classes->new(
  $index->segment
);

is($criterion->to_string, 'classes', 'Stringification');

# Create group query
my $group = Krawfish::Result::Group->new(
  $query->normalize->finalize->identify($index->dict)->optimize($index->segment),
  $criterion
);

# is($group->to_string, "groupBy(classes:#13)", 'Stringification');

ok($group->next, 'Go to next');


# TODO: Return term_ids!
is_deeply($group->current_group, {
  'class_0' => [2,3],
  freq => 1,
  doc_freq => 1
}, 'Correct classes');

ok(!$group->next, 'No more next');

# Complex query
$query = $kq->seq(
  $kq->class($kq->token('akron=Bau-Leiter'), 1),
  $kq->class($kq->token('opennlp/p=V'), 3)
);

is($query->to_string,
   '{1:[akron=Bau-Leiter]}{3:[opennlp/p=V]}',
   'Stringification');

# Create class criterion
$criterion = Krawfish::Result::Group::Classes->new(
  $index->segment,
  1,3
);

is($criterion->to_string, 'classes[1,3]', 'Stringification');


# Create group
$group = Krawfish::Result::Group->new(
  $query->normalize->finalize->identify($index->dict)->optimize($index->segment),
  $criterion
);

is($group->to_string,
   # "groupBy(classes[1,3]:constr(pos=2:class(1:'akron=Bau-Leiter'),class(3:'opennlp/p=V')))",
   "groupBy(classes[1,3]:constr(pos=2:class(1:#9),class(3:#11)))",
   'Stringification'
 );

ok($group->next, 'Go to next');

is_deeply($group->current_group, {
  'class_1' => [2,3],
  'class_3' => [4],
  freq => 1,
  doc_freq => 1
}, 'Correct classes');


done_testing;
__END__
