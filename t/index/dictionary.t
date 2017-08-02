use Krawfish::Index::Dictionary;
use Test::More;
use strict;
use warnings;
use Data::Dumper;

my $dict = Krawfish::Index::Dictionary->new;

ok($dict->add_term2('baum'), 'Add term');
ok($dict->add_term2('balsam'), 'Add term');
ok($dict->add_term2('abenteuer'), 'Add term');

# TODO:
#   This shouldn't be the way! Dict should return
#   a term_id, that will later be used for
#   the postings lists!

is($dict->term_id_by_term2('balsam'), 2, 'Get term id');
is($dict->term_id_by_term2('baum'), 1, 'Get term id');

done_testing;
__END__


# TODO:
#   This shouldn't be the way! Dict should return
#   a term_id, that will later be used for
#   the postings lists!

ok(my $pointer = $dict->pointer('baum'), 'Get term (pointer)');
ok(!$dict->pointer('baumi'), 'Get no term (pointer)');

is($pointer->term_id, 1, 'Correct term_id');
is($dict->pointer('abenteuer')->term_id, 3, 'Correct term_id');

is($dict->term_by_term_id(3), 'abenteuer', 'Correct term');


done_testing;
__END__
