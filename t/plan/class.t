use Test::More;
use strict;
use warnings;
use Data::Dumper;

use_ok('Krawfish::Koral');
use_ok('Krawfish::Index');

my $index = Krawfish::Index->new;

ok(defined $index->add('t/data/doc1.jsonld'), 'Add new document');

my $koral = Krawfish::Koral->new;
my $qb = $koral->query_builder;

my $query = $qb->class($qb->token('der'), 3);
is($query->to_string, '{3:[der]}', 'Stringification');

is($query->plan_for($index)->to_string, "class(3:'der')", 'Planned Stringification');

done_testing;
__END__
