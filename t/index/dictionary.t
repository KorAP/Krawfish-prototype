use Krawfish::Index::Dictionary;
use Unicode::Normalize qw/normalize/;
use Test::More;
use strict;
use warnings;
use Data::Dumper;
use utf8;

my $dict = Krawfish::Index::Dictionary->new;

is($dict->add_term('baum'), 1, 'Add term');
is($dict->add_term('balsam'), 2, 'Add term');
is($dict->add_term('abenteuer'), 3, 'Add term');

# Just retrieve when existing
is($dict->add_term('balsam'), 2, 'Add term');

is($dict->term_id_by_term('balsam'), 2, 'Get term id');
is($dict->term_id_by_term('baum'), 1, 'Get term id');

my $surface = 'grün';
my $gruen_kc = normalize('KC', $surface);
my $gruen_kd = normalize('KD', $surface);

# Add non-normalized terms
is($dict->add_term($gruen_kc), 4, 'Add term');
is($dict->add_term($gruen_kd), 4, 'Add term');

done_testing;
__END__
