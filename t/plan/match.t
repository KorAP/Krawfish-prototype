use Test::More;
use Test::Krawfish;
use strict;
use warnings;

use_ok('Krawfish::Koral');

my $koral = Krawfish::Koral->new;

my $builder = $koral->query_builder;

# Get the match at pos 3 - 10 in document doc-1
my $query = $builder->match(
  'doc-1' => 3,10
);
ok(!$query->is_anywhere, 'Is anywhere');
ok(!$query->is_optional, 'Isn\'t optional');
ok(!$query->is_null, 'Isn\'t null');
ok(!$query->is_negative, 'Isn\'t negative');
ok($query->is_extended, 'Is extended');
is($query->to_string, '[[id=doc-1:3-10]]', 'Stringification');
ok($query = $query->normalize, 'Normalize');
is($query->to_string, '[[id=doc-1:3-10]]', 'Stringification');
ok(!$query->has_error, 'Builder has no error');

done_testing;

__END__
