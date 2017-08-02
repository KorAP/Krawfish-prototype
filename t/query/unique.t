use Test::More;
use Test::Krawfish;
use strict;
use warnings;

use_ok('Krawfish::Index');
use_ok('Krawfish::Koral::Query::Builder');

ok(my $qb = Krawfish::Koral::Query::Builder->new, 'Create Koral::Builder');
my $index = Krawfish::Index->new;
ok_index($index, '[aa|bb][aa|bb][aa|bb]', 'Add new document');

my $query = $qb->token(
  $qb->bool_or('aa', 'bb')
);

is($query->to_string, '[aa|bb]', 'termGroup');
ok(my $non_unique = $query->normalize->finalize->identify($index->dict)->optimize($index->segment), 'TermGroup');
is($non_unique->to_string, "or(#1,#2)", 'termGroup');

matches($non_unique, [qw/[0:0-1]
                         [0:0-1]
                         [0:1-2]
                         [0:1-2]
                         [0:2-3]
                         [0:2-3]/]);



$query = $qb->unique(
  $qb->token(
    $qb->bool_or('aa', 'bb')
  )
);
is($query->to_string, 'unique([aa|bb])', 'termGroup');
ok(my $unique = $query->normalize->finalize->identify($index->dict)->optimize($index->segment), 'TermGroup');
is($unique->to_string, "unique(or(#1,#2))", 'termGroup');

matches($unique, [qw/[0:0-1]
                     [0:1-2]
                     [0:2-3]/]);

done_testing;
__END__

