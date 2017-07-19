use Test::More;
use Test::Krawfish;
use Data::Dumper;
use strict;
use warnings;

use_ok('Krawfish::Index');
use_ok('Krawfish::Koral');

my $index = Krawfish::Index->new;

ok_index($index, {
  docID => 7,
  author => 'Carol'
} => [qw/aa bb/], 'Add complex document');

ok_index($index, {
  docID => 3,
  author => 'Arthur'
} => [qw/aa bb cc/], 'Add complex document');

ok_index($index, {
  docID => 1,
  author => 'Bob'
} => [qw/aa bb cc/], 'Add complex document');


my $koral = Krawfish::Koral->new;
my $kqb = $koral->query_builder;
my $kcb = $koral->corpus_builder;
$koral->query($kqb->term('bb'));
$koral->corpus($kcb->string('author')->eq('Peter'));

is($koral->to_string, 'filterBy(bb,author=Peter)', 'Stringification');

my $query = $koral->normalize->finalize->optimize($index);

# Can't match anywhere:
is($query->to_string, "[0]", 'Planned stringification');

$koral->corpus($kcb->string('author')->eq('Arthur'));
is($koral->to_string, 'filterBy(bb,author=Arthur)', 'Stringification');
$query = $koral->normalize->finalize->optimize($index);

# Can't match anywhere:
#is($query->to_string, "filter('bb',and([1],'author:Arthur'))", 'Planned stringification');
is($query->to_string, "filter('bb','author:Arthur')", 'Planned stringification');

ok($query->next, 'Get next filtered match');
is($query->current->to_string, '[1:1-2]', 'Stringification');

TODO: {
  local $TODO = 'Test further with AND-groups';
};

done_testing;


__END__
