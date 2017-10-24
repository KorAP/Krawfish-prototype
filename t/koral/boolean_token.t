use Test::More;
use Test::Krawfish;
use strict;
use warnings;

use_ok('Krawfish::Koral');
use_ok('Krawfish::Index');

my $index = Krawfish::Index->new;
ok_index($index, '[a|b][a|b|c][a][b|c]', 'Add complex document');


# The problem is, that negativity in tokens is resolved using bool_and_not(any, neg).
# But in tokens, this should probably keep the negativity and move the operand outside the token, like
# [a|b|!c] -> [a|b]|!c. And then sequence optimization may took place.
#
# [(a|b|c)&!d] -> [andnot((a|b|c),d)]
# [(a|b|!c)&d] -> [(a|b)&d|andnot(d,c)]

my $koral = Krawfish::Koral->new;
my $qb = $koral->query_builder;

$koral->query(
  $qb->bool_or(
    $qb->bool_and(
      $qb->term('a'),
      $qb->term('b')
    ),
    $qb->term('c')->is_negative(1)
  )
);

ok(my $query = $koral->to_query, 'Normalize');




todo: {
  local $TODO = 'Moving negations out of groups is currently not supported';

  is($query->to_string, 'filter((a&b)|excl(32:[],c),[1])',
     'Stringification');
  ok($query = $query->identify($index->dict), 'Identify');
  is($query->to_string, '', 'Stringification');
  ok($query = $query->optimize($index->segment), 'Identify');
};


# Move optionality up in or-group
$koral->query(
  $qb->bool_or(
    $qb->term('c'),
    $qb->repeat($qb->term('b'),0,1)
  )
);
ok($query = $koral->to_query, 'Normalize');
is($query->to_string, 'filter((b)|(c),[1])', 'Stringification');



done_testing;
__END__
