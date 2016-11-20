use Test::More;
use strict;
use warnings;
use File::Basename 'dirname';
use File::Spec::Functions 'catfile';
use Data::Dumper;

sub cat_t {
  return catfile(dirname(__FILE__), '..', @_);
};

require '' . cat_t('util', 'CreateDoc.pm');
require '' . cat_t('util', 'TestMatches.pm');

use_ok('Krawfish::Koral::Query::Builder');
use_ok('Krawfish::Index');

my $qb = Krawfish::Koral::Query::Builder->new;

# [aa&!bb]
my $index = Krawfish::Index->new;
ok(defined $index->add(complex_doc('[aa|bb][aa|bb|cc][aa][bb|cc]')), 'Add complex document');
my $token = $qb->token(
  $qb->term_and('aa', $qb->term_neg('bb'))
);
is($token->to_string, '[aa&!bb]', 'Stringification');
ok(my $plan = $token->plan_for($index), 'Planning');
is($plan->to_string, "excl(32:'aa','bb')", 'Stringification');

test_matches($plan, '[0:2-3]');

# [aa&!bb]
$index = Krawfish::Index->new;
ok(defined $index->add(complex_doc('[aa|bb][aa|bb|cc][aa][bb|cc]')), 'Add complex document');
$token = $qb->token(
  $qb->term_or(
    $qb->term_and('aa', $qb->term_neg('bb')),
    $qb->term_and('bb', 'cc')
  )
);
is($token->to_string, '[(aa&!bb)|(bb&cc)]', 'Stringification');
ok($plan = $token->plan_for($index), 'Planning');
is($plan->to_string, "or(excl(32:'aa','bb'),pos(32:'bb','cc'))", 'Stringification');
test_matches($plan, '[0:1-2]', '[0:2-3]','[0:3-4]');



done_testing;
__END__

