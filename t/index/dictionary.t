use Krawfish::Index::Dictionary;
use Test::More;
use strict;
use warnings;
use Data::Dumper;

my $dict = Krawfish::Index::Dictionary->new;

is($dict->add_term('baum'), 1, 'Add term');
is($dict->add_term('balsam'), 2, 'Add term');
is($dict->add_term('abenteuer'), 3, 'Add term');

# Just retrieve when existing
is($dict->add_term('balsam'), 2, 'Add term');

is($dict->term_id_by_term('balsam'), 2, 'Get term id');
is($dict->term_id_by_term('baum'), 1, 'Get term id');


done_testing;
__END__
