use Test::More;
use Test::Krawfish;
use strict;
use warnings;

use_ok('Krawfish::Index');
use_ok('Krawfish::Koral');

use_ok('Krawfish::Util::Bits');
use_ok('Krawfish::Posting::Payload');

my $index = Krawfish::Index->new;

ok_index($index, {
  id => 'doc-2',
  license => 'free'
} => [qw/aa bb/], 'Add complex document');
ok_index($index, {
  id => 'doc-1',
  license => 'free'
} => [qw/aa cc cc/], 'Add complex document');
ok_index($index, {
  id => 'doc-3',
  license => 'closed'
} => [qw/aa bb/], 'Add complex document');



# Single match query
use Krawfish::Koral::Query::Builder;
my $qb = Krawfish::Koral::Query::Builder->new;
my $query = $qb->match('doc-3', 0, 2);

$query = $query->normalize->finalize->identify($index->dict)->optimize($index->segment);

# is($query->to_string, '[[#12:0-2]]', 'Stringification');

ok($query->next, 'First next');
is($query->current->to_string, '[2:0-2]', 'First match');
ok(!$query->next, 'First next');



# Double match query
$query = $qb->bool_or(
  $qb->match('doc-3', 0, 1),
  $qb->match('doc-1', 1, 2)
);

$query = $query->normalize->finalize->identify($index->dict)->optimize($index->segment);

# is($query->to_string, 'or([[#12:0-1]],[[#9:1-2]])', 'Stringification');

ok($query->next, 'First next');
is($query->current->to_string, '[1:1-2]', 'First match');
ok($query->next, 'First next');
is($query->current->to_string, '[2:0-1]', 'First match');
ok(!$query->next, 'First next');


# Triple match query
$query = $qb->bool_or(
  $qb->match('doc-1', 1, 2),
  $qb->match('doc-2', 0, 1),
  $qb->match('doc-3', 0, 1)
);

$query = $query->normalize->finalize->identify($index->dict)->optimize($index->segment);

# is($query->to_string, 'or(or([[#12:0-1]],[[#2:0-1]]),[[#9:1-2]])', 'Stringification');

ok($query->next, 'First next');
is($query->current->to_string, '[0:0-1]', 'First match');
ok($query->next, 'First next');
is($query->current->to_string, '[1:1-2]', 'First match');
ok($query->next, 'First next');
is($query->current->to_string, '[2:0-1]', 'First match');
ok(!$query->next, 'First next');



# Complex single match
my $koral = Krawfish::Koral->new;
my $cb = $koral->corpus_builder;

$koral->query($qb->match('doc-1', 1, 2));

is($koral->to_string,
   "query=[[[id=doc-1:1-2]]]",
   'Stringification');

ok(my $koral_query = $koral->to_query, 'Normalization');

# This is a query that is fine to be send to nodes
# It respects that documents need to be live
is($koral_query->to_string,
   "filter([[id=doc-1:1-2]],[1])",
   'Stringification');

# This is a query that is fine to be send to segments:
ok($koral_query = $koral_query->identify($index->dict), 'Identify');

# This is a query that is fine to be send to nodes
is($koral_query->to_string,
   "filter([[#9:1-2]],[1])",
   'Stringification');

# This is a query that is fine to be send to segments:
ok($koral_query = $koral_query->optimize($index->segment), 'Identify');

# This is a query that is fine to be send to nodes
is($koral_query->to_string,
   "[[and(#9,[1]):1-2]]",
   'Stringification');

matches($koral_query, [qw/[1:1-2]/], 'Get match');



# Complex triple matches
$koral = Krawfish::Koral->new;
$koral->query(
  $qb->bool_or(
    $qb->match('doc-1', 1, 2),
    $qb->match('doc-2', 0, 1),
    $qb->match('doc-3', 0, 1)
  )
);

is($koral->to_string,
   "query=[([[id=doc-1:1-2]])|([[id=doc-2:0-1]])|([[id=doc-3:0-1]])]",
   'Stringification');

ok($koral_query = $koral->to_query, 'Normalization');

# This is a query that is fine to be send to nodes
# It respects that documents need to be live
is($koral_query->to_string,
   "filter(([[id=doc-1:1-2]])|([[id=doc-2:0-1]])|([[id=doc-3:0-1]]),[1])",
   'Stringification');

# This is a query that is fine to be send to segments:
ok($koral_query = $koral_query->identify($index->dict), 'Identify');

# This is a query that is fine to be send to nodes
#is($koral_query->to_string,
#   "filter(([[#12:0-1]])|([[#2:0-1]])|([[#9:1-2]]),[1])",
#   'Stringification');

# This is a query that is fine to be send to segments:
ok($koral_query = $koral_query->optimize($index->segment), 'Identify');

# This is a query that is fine to be send to nodes
#is($koral_query->to_string,
#   "or(or([[and(#12,[1]):0-1]],[[and(#2,[1]):0-1]]),[[and(#9,[1]):1-2]])",
#   'Stringification');

matches($koral_query, [qw/[0:0-1] [1:1-2] [2:0-1]/], 'Matches');



# Some more matches with a filter
$koral = Krawfish::Koral->new;
$koral->query(
  $qb->bool_or(
    $qb->match('doc-1', 1, 2),
    $qb->match('doc-2', 0, 1),
    $qb->match('doc-3', 0, 1)
  )
);

$koral->corpus(
  $cb->string('license')->eq('free')
);

is($koral->to_string,
   "corpus=[license=free],query=[([[id=doc-1:1-2]])|([[id=doc-2:0-1]])|([[id=doc-3:0-1]])]",
   'Stringification');

ok($koral_query = $koral->to_query, 'Normalization');

# This is a query that is fine to be send to nodes
# It respects that documents need to be live
is($koral_query->to_string,
   "filter(([[id=doc-1:1-2]])|([[id=doc-2:0-1]])|([[id=doc-3:0-1]]),license=free)",
   'Stringification');

# This is a query that is fine to be send to segments:
ok($koral_query = $koral_query->identify($index->dict), 'Identify');


# This is a query that is fine to be send to nodes
#is($koral_query->to_string,
#   "filter(([[#12:0-1]])|([[#2:0-1]])|([[#9:1-2]]),#4)",
#   'Stringification');

# This is a query that is fine to be send to segments:
ok($koral_query = $koral_query->optimize($index->segment), 'Identify');


# This is a query that is fine to be send to nodes
#is($koral_query->to_string,
#   "or(or([[and(#12,#4):0-1]],[[and(#2,#4):0-1]]),[[and(#9,#4):1-2]])",
#   'Stringification');

matches($koral_query, [qw/[0:0-1] [1:1-2]/], 'Get match');


my $pl = Krawfish::Posting::Payload->new->add();

# Using flags and payloads
$koral = Krawfish::Koral->new;
$koral->query(
  $qb->bool_or(
    $qb->match('doc-2', 0, 1, undef, [5]),
    $qb->match('doc-1', 0, 2, [[0, 1, 1, 2]], [5,8])
  )
);

$koral->corpus(
  $cb->string('license')->eq('free')
);

is($koral->to_string,
   'corpus=[license=free],query=[([[id=doc-1:0-2!5,8$0,1,1,2]])|([[id=doc-2:0-1!5]])]',
   'Stringification');

ok($koral_query = $koral->to_query, 'Normalization');

is($koral_query->to_string,
   'filter(([[id=doc-1:0-2!5,8$0,1,1,2]])|([[id=doc-2:0-1!5]]),license=free)',
   'Stringification');

# This is a query that is fine to be send to segments:
ok($koral_query = $koral_query->identify($index->dict), 'Identify');

is($koral_query->to_string,
   'filter(([[#2:0-1!5]])|([[#9:0-2!5,8$0,1,1,2]]),#4)',
   'Stringification');

# This is a query that is fine to be send to segments:
ok($koral_query = $koral_query->optimize($index->segment), 'Identify');

matches($koral_query, ['[0:0-1!5]','[1:0-2!5,8$0,1,1,2]'], 'Get match');

done_testing;
__END__
