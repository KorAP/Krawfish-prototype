use strict;
use warnings;
use Test::Krawfish;
use Test::More;

use_ok('Krawfish::Koral::Query::Builder');

my $qb = Krawfish::Koral::Query::Builder->new;

# query is fine
my $q = $qb->length($qb->span('a'),3,5);
is($q->min_span, 1, 'Minimum length'); # There needs to be at least one token
is($q->max_span, -1, 'Minimum length');
is($q->to_string, "length(3-5:<a>)", 'Query is valid');
ok($q = $q->normalize->finalize, 'Normalization');
is($q->to_string, "length(3-5:<a>)", 'Query is valid');


$q = $qb->length($qb->seq($qb->term('a'), $qb->term('b')),3,5);
is($q->min_span, 2, 'Minimum length');
is($q->max_span, 2, 'Maximum length');
is($q->to_string, "length(3-5:ab)", 'Query is valid');
ok($q = $q->normalize->finalize, 'Normalization');
is($q->to_string, "length(3-5:ab)", 'Query is valid');
is($q->min_span, 2, 'Minimum length');
is($q->max_span, 2, 'Minimum length');


# query is null
$q = $qb->length($qb->null,3,5);
is($q->min_span, 0, 'Minimum length');
is($q->max_span, 0, 'Minimum length');

is($q->to_string, "length(3-5:-)", 'Query is valid');
ok($q = $q->normalize, 'Normalization');
is($q->min_span, 0, 'Minimum length');
is($q->max_span, 0, 'Minimum length');
is($q->to_string, "-", 'Query is valid');
ok(!$q->finalize, 'Finalization');
ok($q->has_error, 'Has errors');
is($q->error->[0]->[1], 'This query matches everywhere', 'Error');
ok($q->is_null, 'Matches nowhere');



# query is nowhere
$q = $qb->length($qb->nowhere,3,5);
is($q->to_string, "length(3-5:[0])", 'Query is valid');
is($q->min_span, -1, 'Minimum length');
is($q->max_span, -1, 'Minimum length');
ok($q = $q->normalize, 'Normalization');
is($q->to_string, "[0]", 'Query is valid');
ok($q = $q->finalize, 'Normalization');
ok($q->is_nowhere, 'Matches nowhere');
is($q->min_span, -1, 'Minimum length');
is($q->max_span, -1, 'Minimum length');


# query is anywhere
$q = $qb->length($qb->anywhere,3,5);
is($q->min_span, 1, 'Minimum length');
is($q->max_span, 1, 'Minimum length');
is($q->to_string, "length(3-5:[])", 'Query is valid');
ok($q = $q->normalize, 'Normalization');
is($q->min_span, 1, 'Minimum length');
is($q->max_span, 1, 'Minimum length');


TODO: {
  local $TODO = 'Optimize repetitions';
  $q = $qb->length($qb->repeat($qb->anywhere,0,undef),3,5);
  is($q->to_string, "length(3-5:[]*)", 'Query is valid');
  is($q->min_span, 1, 'Minimum length');
  is($q->max_span, 1, 'Minimum length');
  ok($q = $q->normalize, 'Normalization');
  is($q->min_span, 1, 'Minimum length');
  is($q->max_span, 1, 'Minimum length');
  is($q->to_string, "[]{3,5}", 'Query is valid');
  ok(!$q->finalize, 'Normalization');
  ok($q->is_anywhere, 'Matches everywhere');
  ok(!$q->is_optional, 'Optional');
  is($q->error->[0]->[1], 'Unable to search for anywhere tokens', 'Warning');

  # query is anywhere and optional
  $q = $qb->length($qb->repeat($qb->anywhere,0, undef),0,5);
  is($q->to_string, "length(0-5:[]*)", 'Query is valid');
  ok($q = $q->normalize, 'Normalization');
  is($q->to_string, "[]{0,5}", 'Query is valid');
  ok($q->is_anywhere, 'Matches everywhere');
  ok($q->is_optional, 'Optional');
  ok(!$q->finalize, 'Normalization');
  ok($q->is_anywhere, 'Matches everywhere');
  ok(!$q->is_optional, 'Optional');
#  is($q->warning->[0]->[1], 'Optionality of query is ignored', 'Warning');
#  is($q->error->[0]->[1], 'Unable to search for anywhere tokens', 'Warning');
};


done_testing;
__END__
