use Test::More;
use strict;
use warnings;
use Data::Dumper;
use File::Basename 'dirname';
use File::Spec::Functions 'catfile';


use_ok('Krawfish::Koral');
use_ok('Krawfish::Index');

sub cat_t {
  return catfile(dirname(__FILE__), '..', @_);
};

require '' . cat_t('util', 'CreateDoc.pm');

my $index = Krawfish::Index->new;
my $koral = Krawfish::Koral->new;
my $qb = $koral->query_builder;

ok(defined $index->add(complex_doc('<1:aa>[aa]</1>[bb][aa][bb]')), 'Add new document');

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


# Exclusion that translates to nothing
$query = $qb->exclusion(
  ['isAround'],
  $qb->span('aa'),
  $qb->term_re('h.*')
);
ok(!$query->is_any, 'Is any');
ok(!$query->is_optional, 'Isn\'t optional');
ok(!$query->is_null, 'Isn\'t null');
ok(!$query->is_negative, 'Isn\'t negative');
ok(!$query->is_extended, 'Isn\'t extended');
is($query->to_string, 'excl(128:<aa>,/h.*/)', 'Stringification');
is($query->prepare_for($index)->to_string,
   "'<>aa'", 'Planned Stringification');
ok(!$query->has_error, 'Builder has no error');




diag 'Test further';

# Think about optional, any, negative etc.

done_testing;
__END__
