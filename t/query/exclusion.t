use Test::More;
use Test::Krawfish;
use strict;
use warnings;

use_ok('Krawfish::Koral::Query::Builder');
use_ok('Krawfish::Index');

# TODO:
#   Clone queries!

my $index = Krawfish::Index->new;
my $qb = Krawfish::Koral::Query::Builder->new;
my ($wrap, $query);

# Text exclusion with
# Frames: 'isAround', 'startsWith', 'endsWith', 'matches'
$query = $qb->exclusion(
  [qw/isAround startsWith endsWith matches/],
  $qb->span('aa'),
  $qb->token('bb')
);
is($query->to_string, 'excl(endsWith;isAround;matches;startsWith:<aa>,[bb])', 'Stringification');


# Exclusion planning
ok_index($index, '<1:aa>[bb][bb]</1><2:aa>[cc]</2>', 'Add complex document');
ok($wrap = $query->normalize->finalize->identify($index->dict)->optimize($index->segment), 'Planning');
is($wrap->to_string, "excl(432:#3,#2)",
   'Planned Stringification');
matches($wrap, [qw/[0:2-3]/], 'Matches');


###
# New index - same query
$query = $qb->exclusion(
  [qw/isAround startsWith endsWith matches/],
  $qb->span('aa'),
  $qb->token('bb')
);
$index = Krawfish::Index->new;
ok_index($index, '<1:aa>[bb][bb]</1><2:aa><3:aa>[cc]</3>[bb]</2>', 'Add complex document');
ok_index($index, '<1:aa>[dd]</1><2:aa>[dd][bb]</2><3:aa>[dd]</3>', 'Add complex document');
ok($wrap = $query->normalize->finalize, 'Planning');
is($wrap->to_string, "excl(endsWith;isAround;matches;startsWith:<aa>,bb)",
   'Planned Stringification');
ok($wrap = $query->identify($index->dict), 'Planning');
is($wrap->to_string(1), "excl(endsWith;isAround;matches;startsWith:#3,#2)",
   'Planned Stringification');


ok($wrap = $query->optimize($index->segment), 'Planning');
is($wrap->to_string(1), "excl(432:#3,#2)",
   'Planned Stringification');

matches($wrap, [qw/[0:2-3] [1:0-1] [1:3-4]/], 'Matches');


###
# New index - same query
$query = $qb->exclusion(
  [qw/isAround startsWith endsWith matches/],
  $qb->span('aa'),
  $qb->token('bb')
);
$index = Krawfish::Index->new;
ok_index($index, '<1:aa>[bb][bb]</1><2:aa><3:aa>[cc]</3>[bb]</2>', 'Add complex document');
ok_index($index, '<1:aa>[dd]</1><2:aa>[dd][bb]</2><3:aa>[dd]</3>', 'Add complex document');
ok($wrap = $query->normalize->finalize->identify($index->dict)->optimize($index->segment), 'Planning');
matches($wrap, [qw/[0:2-3] [1:0-1] [1:3-4]/], 'Matches');


###
# Query only excludes startsWith
# Means: Find a <aa> that does not start with [bb]
# TODO:
#   This should be optimized - the buffer is allowed to forget
#   WAY earlier!
$query = $qb->exclusion(
  [qw/startsWith/],
  $qb->span('aa'),
  $qb->token('bb')
);
is($query->to_string, 'excl(startsWith:<aa>,[bb])', 'Stringification');

ok($wrap = $query->normalize->finalize->identify($index->dict)->optimize($index->segment), 'Planning');
is($wrap->to_string, "excl(16:#3,#2)",
   'Planned Stringification');
matches($wrap, [qw/[0:2-3] [0:2-4] [1:0-1] [1:1-3] [1:3-4]/]);


###
# Query only excludes endsWith
# Means: Find a <aa> that does not end with [bb]
$query = $qb->exclusion(
  [qw/endsWith/],
  $qb->span('aa'),
  $qb->token('bb')
);
is($query->to_string, 'excl(endsWith:<aa>,[bb])', 'Stringification');
ok($wrap = $query->normalize->finalize->identify($index->dict)->optimize($index->segment), 'Planning');
is($wrap->to_string, "excl(256:#3,#2)",
   'Planned Stringification');
matches($wrap, [qw/[0:2-3] [1:0-1] [1:3-4]/]);


###
# Query only excludes precedesDirectly
# Means: Find a [bb] that does not preceed another [bb] directly
$query = $qb->exclusion(
  [qw/precedesDirectly/],
  $qb->token('bb'),
  $qb->token('bb')
);
is($query->to_string, 'excl(precedesDirectly:[bb],[bb])', 'Stringification');
ok($wrap = $query->normalize->finalize, 'Planning');

is($wrap->to_string, "excl(precedesDirectly:bb,bb)",
   'Planned Stringification');

ok($wrap = $wrap->identify($index->dict), 'Planning');
is($wrap->to_string(1), "excl(precedesDirectly:#2,#2)",
   'Planned Stringification');
ok($wrap = $wrap->optimize($index->segment), 'Planning');
is($wrap->to_string, "excl(2:#2,#2)",
   'Planned Stringification');
matches($wrap, [qw/[0:1-2] [0:3-4] [1:2-3]/]);


###
# Query only excludes succeedsDirectly
# Means: Find a [bb] that does not succeed another [bb] directly
$query = $qb->exclusion(
  [qw/succeedsDirectly/],
  $qb->token('bb'),
  $qb->token('bb')
);
is($query->to_string, 'excl(succeedsDirectly:[bb],[bb])', 'Stringification');
ok($wrap = $query->normalize->finalize->identify($index->dict)->optimize($index->segment), 'Planning');
is($wrap->to_string, "excl(2048:#2,#2)",
   'Planned Stringification');
matches($wrap, [qw/[0:0-1] [0:3-4] [1:2-3]/]);



###
# Query excludes succeedsDirectly and precedesDirectly
# Means: Find a [bb] that is neither succeeded nor preceded directly by a [bb]
$query = $qb->exclusion(
  [qw/succeedsDirectly precedesDirectly/],
  $qb->token('bb'),
  $qb->token('bb')
);
is($query->to_string, 'excl(precedesDirectly;succeedsDirectly:[bb],[bb])', 'Stringification');
ok($wrap = $query->normalize->finalize->identify($index->dict)->optimize($index->segment), 'Planning');
is($wrap->to_string, "excl(2050:#2,#2)",
   'Planned Stringification');
matches($wrap, [qw/[0:3-4] [1:2-3]/]);


###
# Query only excludes precedesDirectly
# Means: Find a [bb] that is not preceded directly by a [aa]
# The important part here is - match in a doc where B does not occur!
$index = Krawfish::Index->new;
ok_index($index, '[aa|bb][bb]', 'Add complex document');
ok_index($index, '[aa]', 'Add complex document');
ok_index($index, '[aa]', 'Add complex document');

$query = $qb->exclusion(
  [qw/precedesDirectly/],
  $qb->token('aa'),
  $qb->token('bb')
);
is($query->to_string, 'excl(precedesDirectly:[aa],[bb])', 'Stringification');

ok($wrap = $query->normalize->finalize->identify($index->dict)->optimize($index->segment), 'Planning');
is($wrap->to_string, "excl(2:#2,#3)",
   'Planned Stringification');
matches($wrap, [qw/[1:0-1] [2:0-1]/]);



ok_index($index, '[bb]', 'Add complex document');
$query = $qb->exclusion(
  [qw/precedesDirectly/],
  $qb->token('aa'),
  $qb->token('bb')
);
ok($wrap = $query->normalize->finalize->identify($index->dict)->optimize($index->segment), 'Planning');
matches($wrap, [qw/[1:0-1] [2:0-1]/]);



ok_index($index, '[aa][bb]', 'Add complex document');
$query = $qb->exclusion(
  [qw/precedesDirectly/],
  $qb->token('aa'),
  $qb->token('bb')
);
ok($wrap = $query->normalize->finalize->identify($index->dict)->optimize($index->segment), 'Planning');
matches($wrap, [qw/[1:0-1] [2:0-1]/]);


# Example query from the C2 textbook:
#   "Da wegen eigentlich 1.669.349 mal im Archiv belegt ist, wurden durch die
#    obigen Suchanfragen 1.669.349 - 1.669.294 = 55 Fälle nicht abgedeckt.
#    Es handelt sich um Fälle, bei denen wegen außerhalb einer <s> ... </s>
#    Markierung (in einem <byline> außerhalb des Textbody) gefunden wurde.
#    Diese Fälle lassen sich mit folgender Suchanfrage unter Verwendung der
#    Ausschließungsoption % erfragen:
#    Q1 = IN(wegen,'%',ELEM(S))"
$index = Krawfish::Index->new;
ok_index($index, '<1:s>[wegen]</1><2:s>[wegen][aa]</1><2:s>[aa][wegen]</2><3:s>[aa][wegen][aa]</3><4:s>[wegen]</4>[wegen]', 'Add complex document');
$query = $qb->exclusion(
  [qw/alignsRight
      isWithin
      matches
      alignsLeft/],
  $qb->token('wegen'),
  $qb->span('s')
);
ok($wrap = $query->normalize->finalize->identify($index->dict)->optimize($index->segment), 'Planning');
matches($wrap, [qw/[0:9-10]/]);




done_testing;
__END__
