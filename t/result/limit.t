use Test::More;
use Test::Krawfish;
use strict;
use warnings;

use_ok('Krawfish::Index');
use_ok('Krawfish::Koral::Query::Builder');
use_ok('Krawfish::Result::Limit');

my $index = Krawfish::Index->new;

ok(defined $index->add('t/data/doc1.jsonld'), 'Add new document');
ok(defined $index->add('t/data/doc2.jsonld'), 'Add new document');
ok(defined $index->add('t/data/doc3-segments.jsonld'), 'Add new document');

my $kq = Krawfish::Koral::Query::Builder->new;
my $query = $kq->bool_or('Der', 'akron=Der');

# Get sort object
ok(my $sort = Krawfish::Result::Limit->new(
  $query->normalize->finalize->optimize($index),
  1,
  3
), 'Create sort object');

ok($sort->next, 'Next');
is($sort->current->doc_id, 1, 'Obj');
ok($sort->next, 'Next');
is($sort->current->doc_id, 2, 'Obj');
ok(!$sort->next, 'No more nexts');

# Better not stingify
is($sort->to_string, "resultLimit([1-4]:or('akron=Der','Der'))", 'Stringification');

done_testing;
__END__
