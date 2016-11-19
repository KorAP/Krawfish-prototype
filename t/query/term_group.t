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

my $index = Krawfish::Index->new;
my $qb = Krawfish::Koral::Query::Builder->new;

ok(defined $index->add(complex_doc('[aa|bb][aa|bb|cc][aa][bb|cc]')), 'Add complex document');

my $token = $qb->token(
  $qb->term_and('aa', $qb->term_neg('bb'))
);
is($token->to_string, '[aa&!bb]', 'Stringification');
ok(my $plan = $token->plan_for($index), 'Planning');
is($plan->to_string, "excl(32:'aa','bb')", 'Stringification');

done_testing;
__END__
