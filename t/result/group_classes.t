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

#ok(defined $index->add('t/data/doc1.jsonld'), 'Add new document');
#ok(defined $index->add('t/data/doc2.jsonld'), 'Add new document');
ok(defined $index->add('t/data/doc3-segments.jsonld'), 'Add new document');

my $kq = Krawfish::Koral::Query::Builder->new;
my $query = $kq->token('akron=Bau-Leiter');

is($query->to_string, '[akron=Bau-Leiter]', 'Stringification');

# Create class criterion
my $criterion = Krawfish::Result::Group::Classes->new(
  $index->segments
);

is($criterion->to_string, 'classes[0]', 'Stringification');

# Create group
my $group = Krawfish::Result::Group->new(
  $query->prepare_for($index),
  $criterion
);

is($group->to_string, "collectGroups(classes[0]:'akron=Bau-Leiter')", 'Stringification');

ok($group->next, 'Go to next');

is_deeply($group->current_group, {
  'class_0' => ['Bau','Leiter'],
  freq => 1,
  doc_freq => 1
}, 'Correct classes');



done_testing;
__END__
