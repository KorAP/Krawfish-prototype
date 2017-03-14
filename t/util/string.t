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

# From comment in http://archives.miloush.net/michkap/archive/2007/05/14/2629747.html
is(remove_diacritics('ÅåÄäÖö'), 'AaAaOo', 'Check swedish');
# Krawfish::Util::String::_list_props('Łł');
is(remove_diacritics('ĄąĆćĘęŁłŃńÓóŚśŹźŻż'), 'AaCcEeLlNnOoSsZzZz', 'Check polish');
is(remove_diacritics('ľščťžýáíéúäôňďĽŠČŤŽÝÁÍÉÚÄÔŇĎ'), 'lsctzyaieuaondLSCTZYAIEUAOND', 'Check slowakish');
is(remove_diacritics('ëőüűŐÜŰ'), 'eouuOUU', 'Check hungarian');
is(remove_diacritics('Ññ¿'), 'Nn¿', 'Check spanish');
is(remove_diacritics('àèòçï'), 'aeoci', 'Check CA?');
is(remove_diacritics('ı'), 'i', 'Check turkish');

# From http://stackoverflow.com/questions/249087/how-do-i-remove-diacritics-accents-from-a-string-in-net#249126
is(remove_diacritics('äáčďěéíľľňôóřŕšťúůýž'), 'aacdeeillnoorrstuuyz');
is(remove_diacritics('ÄÁČĎĚÉÍĽĽŇÔÓŘŔŠŤÚŮÝŽ'), 'AACDEEILLNOORRSTUUYZ');
is(remove_diacritics('ÖÜË'), 'OUE');
is(remove_diacritics('łŁđĐ'), 'lLdD');
is(remove_diacritics('ţŢşŞçÇ'), 'tTsScC');
is(remove_diacritics('øı'), 'oi');

done_testing;
__END__

