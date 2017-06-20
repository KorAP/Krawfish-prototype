use strict;
use warnings;
use Test::Krawfish;
use Test::More;

use_ok('Krawfish::Koral::Query::Builder');

my $qb = Krawfish::Koral::Query::Builder->new;

# query is fine
my $q = $qb->length($qb->term('a'),3,5);
is($q->to_string, "length(3-5:a)", 'Query is valid');
ok($q = $q->normalize->finalize, 'Normalization');
is($q->to_string, "length(3-5:a)", 'Query is valid');

# query is null
$q = $qb->length($qb->null,3,5);
is($q->to_string, "length(3-5:-)", 'Query is valid');
ok($q = $q->normalize, 'Normalization');
is($q->to_string, "[0]", 'Query is valid');
ok($q = $q->finalize, 'Normalization');
ok($q->is_nothing, 'Matches nowhere');


# query is nothing
$q = $qb->length($qb->nothing,3,5);
is($q->to_string, "length(3-5:[0])", 'Query is valid');
ok($q = $q->normalize, 'Normalization');
is($q->to_string, "[0]", 'Query is valid');
ok($q = $q->finalize, 'Normalization');
ok($q->is_nothing, 'Matches nowhere');

# query is any
$q = $qb->length($qb->any,3,5);
is($q->to_string, "length(3-5:[])", 'Query is valid');
ok($q = $q->normalize, 'Normalization');
is($q->to_string, "[]{3,5}", 'Query is valid');
ok(!$q->finalize, 'Normalization');
ok($q->is_any, 'Matches everywhere');
ok(!$q->is_optional, 'Optional');
is($q->error->[0]->[1], 'Unable to search for any tokens', 'Warning');


# query is any and optional
$q = $qb->length($qb->any,0,5);
is($q->to_string, "length(0-5:[])", 'Query is valid');
ok($q = $q->normalize, 'Normalization');
is($q->to_string, "[]{0,5}", 'Query is valid');
ok($q->is_any, 'Matches everywhere');
ok($q->is_optional, 'Optional');
ok(!$q->finalize, 'Normalization');
ok($q->is_any, 'Matches everywhere');
ok(!$q->is_optional, 'Optional');
is($q->warning->[0]->[1], 'Optionality of query is ignored', 'Warning');
is($q->error->[0]->[1], 'Unable to search for any tokens', 'Warning');

done_testing;
__END__
