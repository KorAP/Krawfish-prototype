use Test::More;
use strict;
use warnings;

use_ok('Krawfish::Koral::Corpus::Builder');
use_ok('Krawfish::Koral::Query::Builder');

ok(my $cb = Krawfish::Koral::Corpus::Builder->new, 'Create CorpusBuilder');
ok(my $qb = Krawfish::Koral::Query::Builder->new, 'Create CorpusBuilder');

ok(my $corpus = $cb->string('genre')->eq('novel'), 'Create corpus query');

# [aa][bb]{0,2}
ok(my $query = $qb->seq(
  $qb->token('aa'),
  $qb->repeat($qb->token('bb'),0,2)
), 'Create span query');

ok($query = $qb->filter_by($query, $corpus), 'Filter by corpus');
is($query->to_string, 'filter([aa][bb]{0,2},genre=novel)', 'stringification');
is($query->min_span, 1, 'Span length');
is($query->max_span, 3, 'Span length');
ok($query = $query->normalize->finalize, 'Create query plan');
is($query->to_string, 'filter(aabb{0,2},genre=novel)', 'stringification');
is($query->min_span, 1, 'Span length');
is($query->max_span, 3, 'Span length');

done_testing;
__END__

