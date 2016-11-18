use Test::More;
use strict;
use warnings;
use Data::Dumper;

use_ok('Krawfish::Koral');
use_ok('Krawfish::Index');

my $index = Krawfish::Index->new;
my $koral = Krawfish::Koral->new;
my $qb = $koral->query_builder;

# Exclusion planning

# isAround(<opennlp/c=NP>, Der)
my $query = $qb->exclusion(
  ['isAround'],
  $qb->span('aa'),
  $qb->token('bb')
);
ok(!$query->is_any, 'Is any');
ok(!$query->is_optional, 'Isn\'t optional');
ok(!$query->is_null, 'Isn\'t null');
ok(!$query->is_negative, 'Isn\'t negative');
ok(!$query->is_extended, 'Isn\'t extended');
is($query->to_string, 'excl(128:<aa>,[bb])', 'Stringification');
is($query->prepare_for($index)->to_string,
   "excl(128:'<>aa','bb')", 'Planned Stringification');
ok(!$query->has_error, 'Builder has no error');

diag 'Test further';

# Think about optional, any, negative etc.

done_testing;
__END__
