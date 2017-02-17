use Krawfish::Index::Dictionary;
use Test::More;
use strict;
use warnings;
use Data::Dumper;

my $dict = Krawfish::Index::Dictionary->new;

ok($dict->add_term('baum'), 'Add term');
ok($dict->add_term('balsam'), 'Add term');
ok($dict->add_term('abenteuer'), 'Add term');

ok(my $pointer = $dict->pointer('baum'), 'Get term (pointer)');
ok(!$dict->pointer('baumi'), 'Get no term (pointer)');

is($pointer->term_id, 1, 'Correct term_id');
is($dict->pointer('abenteuer')->term_id, 3, 'Correct term_id');

is($dict->term_by_term_id(3), 'abenteuer', 'Correct term');


done_testing;
__END__
