use Test::More;
use strict;
use warnings;
use Data::Dumper;
use File::Basename 'dirname';
use File::Spec::Functions 'catfile';

use_ok('Krawfish::Index');
use_ok('Krawfish::Koral::Query::Builder');

my $index = Krawfish::Index->new;

sub cat_t {
  return catfile(dirname(__FILE__), '..', @_);
};

require '' . cat_t('util', 'CreateDoc.pm');

ok(my $qb = Krawfish::Koral::Query::Builder->new, 'Add new_document');

ok(my $re = $qb->regex('Der.*'), 'Regex');
is($re->to_string, '/Der.*/', 'Stringification');



ok($re = $qb->term('a/l~P.*?'), 'Regex');
is($re->to_string, 'a/l~P.*?', 'Stringification');
ok($re->is_regex, 'Term is regex');
is($re->match, '~', 'Match operator');

ok(defined $index->add(complex_doc('[a/b=CDE|a/c=FGH][a/l=PART|a/l=BAU|a/l=PUM][b/c=DAU][e/f=UM]')), 'Add doc');

ok(my $plan = $re->plan_for($index), 'Plan Regex');
is($plan->to_string, "or('a/l=PART','a/l=PUM')", 'Stringification');


ok($re = $qb->term('f/l~G.*?'), 'Regex');
is($re->to_string, 'f/l~G.*?', 'Stringification');
ok(!$re->plan_for($index), 'Plan Regex');

done_testing;
__END__
