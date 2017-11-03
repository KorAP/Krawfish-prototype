use Test::More;
use Test::Krawfish;
use Krawfish::Util::Constants qw/:PREFIX/;
use strict;
use warnings;

use_ok('Krawfish::Index');
use_ok('Krawfish::Koral');

my $index = Krawfish::Index->new;
ok_index($index, {
  id => 'doc-1',
  license => 'free',
  corpus => 'corpus-2'
} => [qw/aa bb aa bb/], 'Add new document');

my $koral = Krawfish::Koral->new;
my $qb = $koral->query_builder;
my $mb = $koral->compilation_builder;

$koral->query(
  $qb->bool_or(
    $qb->class($qb->term('aa'),2),
    $qb->class($qb->term('bb'),4)
  )
);

$koral->compilation(
  $mb->enrich(
    $mb->e_terms(2,4)
  )
);

is($koral->to_string,
   "compilation=[enrich=[terms:[2,4]]],query=[({2:aa})|({4:bb})]",
   'Stringification');

ok(my $koral_query = $koral->to_query, 'Normalization');

# This is a query that is fine to be send to nodes
is($koral_query->to_string,
   "terms(2,4:filter(({2:aa})|({4:bb}),[1]))",
   'Stringification');

# This is a query that is fine to be send to segments:
ok($koral_query = $koral_query->identify($index->dict), 'Identify');

# This is a query that is fine to be send to nodes
is($koral_query->to_string,
   "terms(2,4:filter(({2:#8})|({4:#10}),[1]))",
   'Stringification');

ok(my $query = $koral_query->optimize($index->segment), 'Optimize');
is ($query->to_string, 'terms(2,4:or(class(2:filter(#8,[1])),class(4:filter(#10,[1]))))', 'Stringification');

ok($query->next, 'Next match');
is($query->current_match->to_string, '[0:0-1$0,2,0,1|terms:[2:7]]', 'Current match');

is($index->dict->term_by_term_id(7), SUBTERM_PREF . 'aa', 'Get term');

my $match = $query->current_match->inflate($index->dict);
is($match->to_string,
   '[0:0-1$0,2,0,1|terms:[2:' . SUBTERM_PREF . 'aa]]',
   'Current match');

ok($query->next, 'Next match');
is($query->current_match->to_string,
   '[0:1-2$0,4,1,2|terms:[4:9]]', 'Current match');
is($query->current_match->inflate($index->dict)->to_string,
   '[0:1-2$0,4,1,2|terms:[4:' . SUBTERM_PREF . 'bb]]', 'Current match');

ok($query->next, 'Next match');
is($query->current_match->inflate($index->dict)->to_string,
   '[0:2-3$0,2,2,3|terms:[2:' . SUBTERM_PREF . 'aa]]', 'Current match');

ok($query->next, 'Next match');
is($query->current_match->inflate($index->dict)->to_string,
   '[0:3-4$0,4,3,4|terms:[4:' . SUBTERM_PREF . 'bb]]', 'Current match');

ok(!$query->next, 'No nNext match');




# TODO:
#   Replace with clone of above query
$koral = Krawfish::Koral->new;
$koral->query(
  $qb->bool_or(
    $qb->class($qb->term('aa'),2),
    $qb->class($qb->term('bb'),4)
  )
);
$koral->compilation(
  $mb->enrich(
    $mb->e_terms(2,4)
  )
);

ok(my $result = $koral->to_query
     ->identify($index->dict)
     ->optimize($index->segment)
     ->compile
     ->inflate($index->dict)
     ->to_koral_query,
   'Serialize KQ');

is_deeply($result->{matches}->[0]->{terms}->[0]->{'terms'}, ['aa'], 'Check terms');
is($result->{matches}->[0]->{terms}->[0]->{'classOut'}, 2, 'Check terms');
is_deeply($result->{matches}->[1]->{terms}->[0]->{'terms'}, ['bb'], 'Check terms');
is($result->{matches}->[1]->{terms}->[0]->{'classOut'}, 4, 'Check terms');


TODO: {
  local $TODO = 'Test with longer matches and overlaps'
};

done_testing;
__END__
