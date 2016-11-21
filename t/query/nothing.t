use Test::More;
use strict;
use warnings;
use Data::Dumper;
use File::Basename 'dirname';
use File::Spec::Functions 'catfile';

use_ok('Krawfish::Query::Nothing');

ok(my $q = Krawfish::Query::Nothing->new, 'New nothing');
ok(!$q->next, 'No nothing');
ok(!$q->skip_doc, 'No nothing');
is($q->to_string, '[0]', 'Nada');
ok(!$q->current, 'No nothing');

done_testing;
__END__
