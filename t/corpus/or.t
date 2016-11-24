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

use_ok('Krawfish::Koral::Corpus::Builder');
use_ok('Krawfish::Index');

my $index = Krawfish::Index->new;
ok(defined $index->add(simple_doc({id => 2} => qw/aa bb/)), 'Add complex document');
ok(defined $index->add(simple_doc({id => 3} => qw/aa bb/)), 'Add complex document');
ok(defined $index->add(simple_doc({id => 5} => qw/aa bb/)), 'Add complex document');

ok(my $cb = Krawfish::Koral::Corpus::Builder->new, 'Create CorpusBuilder');

ok(my $query = $cb->field_or(
  $cb->string('id')->eq('3'),
  $cb->string('id')->eq('2')
), 'Create corpus query');

is($query->to_string, 'id=3|id=2', 'Stringification');

ok(my $plan = $query->plan_for($index), 'Planning');

is($plan->to_string, "or('id:3','id:2')", 'Stringification');

diag 'Test further';

done_testing;
__END__
