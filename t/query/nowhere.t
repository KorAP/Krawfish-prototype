use Test::More;
use strict;
use warnings;
use Data::Dumper;
use File::Basename 'dirname';
use File::Spec::Functions 'catfile';

use_ok('Krawfish::Query::Nowhere');

ok(my $q = Krawfish::Query::Nowhere->new, 'New nowhere');
ok(!$q->next, 'No nowhere');
ok(!$q->skip_doc, 'No nowhere');
is($q->to_string, '[0]', 'Nada');
ok(!$q->current, 'No nowhere');

done_testing;
__END__
