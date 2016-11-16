use Test::More;
use strict;
use warnings;
use Data::Dumper;
use File::Basename 'dirname';
use File::Spec::Functions 'catfile';

use_ok('Krawfish::Index');
use_ok('Krawfish::Koral::Query::Builder');

sub cat_t {
  return catfile(dirname(__FILE__), '..', @_);
};

require '' . cat_t('util', 'CreateDoc.pm');
require '' . cat_t('util', 'TestMatches.pm');

ok(my $qb = Krawfish::Koral::Query::Builder->new, 'Create Koral::Builder');
my $index = Krawfish::Index->new;
ok(defined $index->add(complex_doc('[aa|bb][aa|bb][aa|bb]')), 'Add new document');

my $query = $qb->token(
  $qb->term_or('aa', 'bb')
);
is($query->to_string, '[aa|bb]', 'termGroup');
ok(my $non_unique = $query->plan_for($index), 'TermGroup');
is($non_unique->to_string, "or('aa','bb')", 'termGroup');

test_matches($non_unique, qw/[0:0-1]
                             [0:0-1]
                             [0:1-2]
                             [0:1-2]
                             [0:2-3]
                             [0:2-3]/);


# TODO: RESET
$index = Krawfish::Index->new;
ok(defined $index->add(complex_doc('[aa|bb][aa|bb][aa|bb]')), 'Add new document');

$query = $qb->unique(
  $qb->token(
    $qb->term_or('aa', 'bb')
  )
);
is($query->to_string, 'unique([aa|bb])', 'termGroup');
ok(my $unique = $query->plan_for($index), 'TermGroup');
is($unique->to_string, "unique(or('aa','bb'))", 'termGroup');

test_matches($unique, qw/[0:0-1]
                         [0:1-2]
                         [0:2-3]/);



done_testing;
__END__

