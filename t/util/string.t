#!/url/bin/env perl
use strict;
use warnings;
use Test::More;
use utf8;
use Mojo::Util qw/encode decode/;

use_ok('Krawfish::Util::String');

is(fold_case('aaa'), 'aaa', 'Case fold 1');
is(fold_case('AAA'), 'aaa', 'Case fold 2');
is(fold_case('AaA'), 'aaa', 'Case fold 3');

is(fold_case('aäa'), 'aäa', 'Case fold 4');
is(fold_case('aÄß'), 'aäss', 'Case fold 5');
is(fold_case('a-Äß'), 'a-äss', 'Case fold 6');
is(fold_case('ÄÖÜß'), 'äöüss', 'Case fold 7');

is(remove_diacritics('Česká'), 'Ceska', 'Removed diacritics');
is(remove_diacritics('Äößa'), 'Aoßa', 'Removed diacritics');

done_testing;
__END__

