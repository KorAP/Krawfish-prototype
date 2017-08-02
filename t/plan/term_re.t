use Test::More;
use Test::Krawfish;
use strict;
use warnings;

use_ok('Krawfish::Index');
use_ok('Krawfish::Koral::Query::Builder');

my $index = Krawfish::Index->new;
ok(my $qb = Krawfish::Koral::Query::Builder->new, 'Add new_document');

ok(my $re = $qb->term_re('Der.*'), 'Regex');
is($re->to_string, '/Der.*/', 'Stringification');
is($re->min_span, 1, 'Span length');
is($re->max_span, 1, 'Span length');


ok($re = $qb->term('a/l~P.*?'), 'Regex');
is($re->to_string, 'a/l~P.*?', 'Stringification');
ok($re->is_regex, 'Term is regex');
is($re->match, '~', 'Match operator');
is($re->min_span, 1, 'Span length');
is($re->max_span, 1, 'Span length');

ok_index($index,'[a/b=CDE|a/c=FGH][a/l=PART|a/l=BAU|a/l=PUM][b/c=DAU][e/f=UM]', 'Add doc');


ok(my $plan = $re->normalize->finalize->identify($index->dict)->optimize($index->segment), 'Plan Regex');
is($plan->to_string, "or(#3,#5)", 'Stringification');


ok($re = $qb->term('f/l~G.*?'), 'Regex');
is($re->to_string, 'f/l~G.*?', 'Stringification');
ok($plan = $re->normalize->finalize->identify($index->dict)->optimize($index->segment), 'Plan Regex');
is($plan->to_string, "[0]", 'Stringification');

done_testing;
__END__
