use strict;
use warnings;
use Test::More;

use_ok('Krawfish::Index');
use_ok('Krawfish::Posting::Token');

ok(my $index = Krawfish::Index->new, 'New index');

my $dict = $index->dict;

ok($dict->add_term('a')->append(0,2,3), 'Add entry');
ok($dict->add_term('a')->append(1,5,6), 'Add entry');

my $first = $dict->pointer('a');
my $second = $dict->pointer('a');

ok($first->next, 'Init posting list');
is_deeply($first->current, '[0$2,3]', 'First posting');
ok($first->next, 'More postings');
is_deeply($first->current, '[1$5,6]', 'First posting');
ok(!$first->next, 'No more postings');

ok($second->next, 'Init posting list');
is_deeply($second->current, '[0$2,3]', 'First posting');
ok($second->next, 'More postings');
is_deeply($second->current, '[1$5,6]', 'First posting');
ok(!$second->next, 'No more postings');

done_testing;
__END__
