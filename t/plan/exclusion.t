use Test::More;
use Test::Krawfish;
use strict;
use warnings;

use_ok('Krawfish::Koral');
use_ok('Krawfish::Index');

my $index = Krawfish::Index->new;
my $koral = Krawfish::Koral->new;
my $qb = $koral->query_builder;

ok_index($index, '<1:aa>[aa]</1>[bb][aa][bb]', 'Add new document');

# Exclusion planning

# isAround(<opennlp/c=NP>, Der)
my $query = $qb->exclusion(
  ['isAround'],
  $qb->span('aa'),
  $qb->token('bb')
);
is($query->min_span, 0, 'Span length');
is($query->max_span, -1, 'Span length');
ok(!$query->is_any, 'Is any');
ok(!$query->is_optional, 'Isn\'t optional');
ok(!$query->is_null, 'Isn\'t null');
ok(!$query->is_negative, 'Isn\'t negative');
ok(!$query->is_extended, 'Isn\'t extended');
is($query->to_string, 'excl(128:<aa>,[bb])', 'Stringification');
ok($query = $query->normalize, 'Normalization');
is($query->to_string, 'excl(128:<aa>,bb)', 'Stringification');
ok(!$query->has_error, 'Builder has no error');
ok($query = $query->optimize($index), 'Optimization');
is($query->to_string, "excl(128:'<>aa','bb')", 'Stringification');

# Exclusion that translates to nothing
$query = $qb->exclusion(
  ['isAround'],
  $qb->span('aa'),
  $qb->term_re('h.*')
);
is($query->min_span, 0, 'Span length');
is($query->max_span, -1, 'Span length');
ok(!$query->is_any, 'Is any');
ok(!$query->is_optional, 'Isn\'t optional');
ok(!$query->is_null, 'Isn\'t null');
ok(!$query->is_negative, 'Isn\'t negative');
ok(!$query->is_extended, 'Isn\'t extended');
is($query->to_string, 'excl(128:<aa>,/h.*/)', 'Stringification');
ok(!$query->has_error, 'Builder has no error');
ok($query = $query->normalize, 'Normalization');
is($query->to_string, 'excl(128:<aa>,/h.*/)', 'Stringification');
ok($query = $query->inflate($index->dict), 'Optimization');
is($query->to_string, "excl(128:<aa>,[0])", 'Stringification');
ok($query = $query->normalize, 'Normalization');
is($query->to_string, "<aa>", 'Stringification');
ok($query = $query->optimize($index), 'Optimization');
is($query->to_string, "'<>aa'", 'Stringification');

# Exclusion that translates to nothing
$query = $qb->exclusion(
  ['isAround'],
  $qb->term('aa'),
  $qb->term_re('h.*')
);
is($query->min_span, 1, 'Span length');
is($query->max_span, 1, 'Span length');


TODO: {
  local $TODO = 'Test further'
};

# Think about optional, any, negative etc.

done_testing;
__END__
