use Krawfish::Index::Subtokens;
use Test::More;
use strict;
use warnings;
use Data::Dumper;

my $subt = Krawfish::Index::Subtokens->new;

# Store doc_id, segment, start_char, end_char
ok($subt->store(1, 0, 0, 5), 'Store');
ok($subt->store(1, 1, 6, 19), 'Store');
ok($subt->store(1, 2, 20, 26), 'Store');

ok($subt->store(2, 0, 0, 7), 'Store');
ok($subt->store(2, 1, 9, 23), 'Store');
ok($subt->store(2, 2, 25, 40), 'Store');

is_deeply($subt->get(2,1), [9, 23], 'Retrieve');

done_testing;
__END__
