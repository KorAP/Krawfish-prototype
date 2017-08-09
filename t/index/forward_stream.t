use strict;
use warnings;
use utf8;
use Test::More;
use Test::Krawfish;
use Data::Dumper;

use_ok('Krawfish::Koral::Document');
use_ok('Krawfish::Koral');
use_ok('Krawfish::Index');


# Add some data
ok(my $doc = Krawfish::Koral::Document->new(
  't/data/doc3-segments.jsonld'
), 'Load document');

ok(my $index = Krawfish::Index->new, 'Create new index');

# Transform dictionary to term_id stream
ok($doc = $doc->identify($index->dict), 'Translate to term identifiers');

# Add document to segment
my $doc_id = $index->segment->add($doc);
is($doc_id, 0, 'Doc id well added');

# Get objects for querying
my $koral = Krawfish::Koral->new;
my $qb = $koral->query_builder;
my $query;


# Check data by query retrieval
# Search for <akron/c=NP>
$koral->query($qb->span('akron/c=NP'));
ok($query = $koral->to_query->identify($index->dict)->optimize($index->segment),
   'Materialize');
is($query->to_string, 'filter(#10,[1])', 'Stringification');
matches($query, [qw/[0:0-3] [0:4-8]/], 'Search');



# Search for akron=Bau-Leiter
$koral->query($qb->token('akron=Bau-Leiter'));
ok($query = $koral->to_query->identify($index->dict)->optimize($index->segment),
   'Materialize');
is($query->to_string, 'filter(#13,[1])', 'Stringification');
matches($query, [qw/[0:1-3]/], 'Search');



# Search for position(startsWith|endsWith:<akron/c=NP>,akron=Bau-Leiter)
$koral->query(
  $qb->position(
    [qw/endsWith startsWith/],
    $qb->span('akron/c=NP'),
    $qb->token('akron=Bau-Leiter')
  )
);
ok($query = $koral->to_query->identify($index->dict)->optimize($index->segment),
   'Create query');
is($query->to_string, 'constr(pos=272:#10,filter(#13,[1]))', 'Stringification');
matches($query, [qw/[0:0-3]/], 'Search');


diag 'Test forward index!';

done_testing;
__END__
