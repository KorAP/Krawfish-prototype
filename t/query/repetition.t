use Test::More;
use strict;
use warnings;
use Data::Dumper;
use File::Basename 'dirname';
use File::Spec::Functions 'catfile';

sub cat_t {
  return catfile(dirname(__FILE__), '..', @_);
};

require '' . cat_t('util', 'CreateDoc.pm');
require '' . cat_t('util', 'TestMatches.pm');

use_ok('Krawfish::Index');
use_ok('Krawfish::Koral::Query::Builder');

my $index = Krawfish::Index->new;

ok(defined $index->add(simple_doc(qw/aa bb bb bb bb cc/)), 'Add new document');
#ok(defined $index->add(simple_doc(qw/bb bb bb bb bb cc/)), 'Add new document');

my $qb = Krawfish::Koral::Query::Builder->new;

ok(my $wrap = $qb->repeat( $qb->token('bb'), 2, 3), 'Repeat');
is($wrap->to_string, '[bb]{2,3}', 'Stringification');
ok(my $rep = $wrap->plan_for($index), 'Rewrite');
is($rep->to_string, "rep(2-3:'bb')", 'Stringification');

# Expect:
# aa [bb bb] bb bb cc
# aa [bb bb bb] bb cc
# aa bb [bb bb] bb cc
# aa bb [bb bb bb] cc
# aa bb bb [bb bb] cc

ok($rep->next, 'Init');
is($rep->current->to_string, '[0:1-3]', 'Match');
ok($rep->next, 'More');
is($rep->current->to_string, '[0:1-4]', 'Match');
ok($rep->next, 'No more');
is($rep->current->to_string, '[0:2-4]', 'Match');
ok($rep->next, 'No more');
is($rep->current->to_string, '[0:2-5]', 'Match');
ok($rep->next, 'No more');
is($rep->current->to_string, '[0:3-5]', 'Match');
ok(!$rep->next, 'No more');

# test_matches($rep, qw/[0:1-3] [0:1-4] [0:2-4] [0:2-5] [0:3-5]/);


# Next test
$index = Krawfish::Index->new;
ok(defined $index->add(simple_doc(qw/aa bb bb bb cc/)), 'Add new document');
ok(defined $index->add(simple_doc(qw/bb bb bb bb cc/)), 'Add new document');

ok($wrap = $qb->repeat( $qb->token('bb'), 1, 3), 'Repeat');
is($wrap->to_string, '[bb]{1,3}', 'Stringification');
ok($rep = $wrap->plan_for($index), 'Rewrite');
is($rep->to_string, "rep(1-3:'bb')", 'Stringification');

test_matches($rep, qw/[0:1-2]
                      [0:1-3]
                      [0:1-4]
                      [0:2-3]
                      [0:2-4]
                      [0:3-4]
                      [1:0-1]
                      [1:0-2]
                      [1:0-3]
                      [1:1-2]
                      [1:1-3]
                      [1:1-4]
                      [1:2-3]
                      [1:2-4]
                      [1:3-4]/);


done_testing;
__END__



