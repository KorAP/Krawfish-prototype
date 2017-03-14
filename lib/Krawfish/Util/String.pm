package Krawfish::Util::String;
use strict;
use warnings;

# Potentially use Unicode::UCD instead
use Unicode::CaseFold;
use Unicode::Normalize qw/getCombinClass normalize/;

use parent 'Exporter';

our @EXPORT = qw/fold_case remove_diacritics normalize_nfkc/;

sub fold_case {
  fc $_[0];
};

# http://archives.miloush.net/michkap/archive/2007/05/14/2629747.html
# http://stackoverflow.com/questions/249087/how-do-i-remove-diacritics-accents-from-a-string-in-net#249126
# http://stackoverflow.com/questions/2992066/code-to-strip-diacritical-marks-using-icu
sub remove_diacritics {
  my $norm = normalize('D',$_[0]);

  # Check character properties with
  # Unicode::Properties 'uniprops';
  $norm =~ s/\p{InCombiningDiacriticalMarks}//g;
  return normalize('C', $norm);
};

sub normalize_nfkc {
  return normalize('KC',$_[0]);
};

1;
