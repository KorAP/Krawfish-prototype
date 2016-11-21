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
ok(defined $index->add(complex_doc('[aa|bb][aa|bb|cc][aa][bb|cc]')), 'Add complex document');

ok(my $cb = Krawfish::Koral::Corpus::Builder->new, 'Create CorpusBuilder');

diag 'Test further';

done_testing;
__END__
