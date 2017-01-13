use Krawfish::Index::Segments;
use Test::More;
use strict;
use warnings;
use Data::Dumper;

my $segs = Krawfish::Index::Segments->new;

# Store doc_id, segment, start_char, end_char
ok($segs->store(1, 0, 0, 5), 'Store');
ok($segs->store(1, 1, 6, 19), 'Store');
ok($segs->store(1, 2, 20, 26), 'Store');

ok($segs->store(2, 0, 0, 7), 'Store');
ok($segs->store(2, 1, 9, 23), 'Store');
ok($segs->store(2, 2, 25, 40), 'Store');

is_deeply($segs->get(2,1), [9, 23], 'Retrieve');

done_testing;
__END__
