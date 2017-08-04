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

ok(defined $index->add('t/data/doc3-segments.jsonld'), 'Add new document');

my $kq = Krawfish::Koral::Query::Builder->new;

# Simple query
my $query = $kq->token('akron=Bau-Leiter');

is($query->to_string, '[akron=Bau-Leiter]', 'Stringification');

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

is($group->to_string, "groupBy(classes:#9)", 'Stringification');

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
