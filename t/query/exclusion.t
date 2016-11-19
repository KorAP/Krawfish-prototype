use Test::More;
use strict;
use warnings;
use File::Basename 'dirname';
use File::Spec::Functions 'catfile';
use Data::Dumper;

sub cat_t {
  return catfile(dirname(__FILE__), '..', @_);
};

require '' . cat_t('util', 'CreateDoc.pm');
require '' . cat_t('util', 'TestMatches.pm');

use_ok('Krawfish::Koral::Query::Builder');
use_ok('Krawfish::Index');

my $index = Krawfish::Index->new;
my $qb = Krawfish::Koral::Query::Builder->new;

# Exclusion planning

ok(defined $index->add(complex_doc('<1:aa>[bb][bb]</1><2:aa>[cc]</2>')), 'Add complex document');

my $query = $qb->exclusion(
  [qw/isAround startsWith endsWith matches/],
  $qb->span('aa'),
  $qb->token('bb')
);
is($query->to_string, 'excl(432:<aa>,[bb])', 'Stringification');
ok(my $wrap = $query->plan_for($index), 'Planning');
is($wrap->to_string, "excl(432:'<>aa','bb')",
   'Planned Stringification');

ok($wrap->next, 'Init');
is($wrap->current->to_string, '[0:2-3]', 'Match');
ok(!$wrap->next, 'No more');



done_testing;
__END__
