use Test::More;
use strict;
use warnings;
use Data::Dumper;
use File::Basename 'dirname';
use File::Spec::Functions 'catfile';

use_ok('Krawfish::Index');
use_ok('Krawfish::Koral::Query::Builder');

my $index = Krawfish::Index->new('index.dat');

sub cat_t {
  return catfile(dirname(__FILE__), '..', @_);
};

ok(defined $index->add(cat_t('data','doc3-segments.jsonld')), 'Add new document');

ok(my $qb = Krawfish::Koral::Query::Builder->new, 'Create Koral::Builder');

ok(my $wrap = $qb->span('akron/c=NP'), 'Span');
ok(my $span = $wrap->normalize->finalize->optimize($index), 'Span');
ok(!$span->current, 'Not initialized yet');

is($span->freq, 2, 'Frequency');

ok($span->next, 'Init search');
is($span->current->to_string, '[0:0-3]', 'Found string');
ok($span->next, 'More tokens');
is($span->current->to_string, '[0:4-8]', 'Found string');
ok(!$span->next, 'No more tokens');


done_testing;

__END__



