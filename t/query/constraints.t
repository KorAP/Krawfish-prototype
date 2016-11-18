use strict;
use warnings;
use Test::More;
use File::Basename 'dirname';
use File::Spec::Functions 'catfile';

use Krawfish::Query::Constraint::Position;

sub cat_t {
  return catfile(dirname(__FILE__), '..', @_);
};

require '' . cat_t('util', 'CreateDoc.pm');
require '' . cat_t('util', 'TestMatches.pm');

use_ok('Krawfish::Index');
use_ok('Krawfish::Koral::Query::Builder');

my $index = Krawfish::Index->new;
ok(defined $index->add(complex_doc('[aa|aa][bb|bb]')), 'Add complex document');

my $qb = Krawfish::Koral::Query::Builder->new;

my $wrap = $qb->constraints(
  [$qb->c_position('precedesDirectly')],
  $qb->token('aa'),
  $qb->token('bb')
);

is($wrap->to_string, "constr(pos=precedesDirectly:[aa],[bb])", 'Query is valid');
ok(my $query = $wrap->plan_for($index), 'Planning');
is($query->to_string, "constr(pos=2:'aa','bb')", 'Query is valid');
test_matches($query, qw/[0:0-2] [0:0-2] [0:0-2] [0:0-2]/);

$index = Krawfish::Index->new;
ok(defined $index->add(simple_doc(qw/aa bb aa bb aa bb/)), 'Add complex document');

# This equals to [aa]{5:[]+}[bb]
$wrap = $qb->constraints(
  [$qb->c_position('precedes'), $qb->c_class_distance(5)],
  $qb->token('aa'),
  $qb->token('bb')
);

is($wrap->to_string, "constr(pos=precedes,class=5:[aa],[bb])", 'Query is valid');
ok($query = $wrap->plan_for($index), 'Planning');
is($query->to_string, "constr(pos=1,class=5:'aa','bb')", 'Query is valid');

test_matches($query, '[0:0-4$0,5,1,2]','[0:0-6$0,5,1,4]','[0:2-6$0,5,3,4]');

$index = Krawfish::Index->new;
ok(defined $index->add(simple_doc(qw/aa bb aa bb aa bb/)), 'Add complex document');

# This equals to [aa]{5:[]*}[bb]
$wrap = $qb->constraints(
  [$qb->c_position('precedes', 'precedesDirectly'), $qb->c_class_distance(5)],
  $qb->token('aa'),
  $qb->token('bb')
);

is($wrap->to_string, "constr(pos=precedes;precedesDirectly,class=5:[aa],[bb])", 'Query is valid');
ok($query = $wrap->plan_for($index), 'Planning');
is($query->to_string, "constr(pos=3,class=5:'aa','bb')", 'Query is valid');

test_matches(
  $query,
  '[0:0-2]',
  '[0:0-4$0,5,1,2]',
  '[0:0-6$0,5,1,4]',
  '[0:2-4]',
  '[0:2-6$0,5,3,4]',
  '[0:4-6]',
);

done_testing;

__END__
