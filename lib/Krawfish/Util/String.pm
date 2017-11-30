package Krawfish::Util::String;
use strict;
use warnings;
# Potentially use Unicode::UCD instead
use Unicode::CaseFold;
use Scalar::Util qw/looks_like_number/;
use Mojo::Util qw/b64_encode/;
use Unicode::Normalize qw/getCombinClass normalize/;
use parent 'Exporter';
use utf8;


# Helper package for unicode handling

our @EXPORT = qw/fold_case
                 remove_diacritics
                 normalize_nfkc
                 squote
                 unsquote
                 binary_short/;


# Fold case of a term
sub fold_case {
  fc $_[0];
};


# Remove diacritics from characters
# http://archives.miloush.net/michkap/archive/2007/05/14/2629747.html
# http://stackoverflow.com/questions/249087/how-do-i-remove-diacritics-accents-from-a-string-in-net#249126
# http://stackoverflow.com/questions/2992066/code-to-strip-diacritical-marks-using-icu
sub remove_diacritics {
  my $norm = normalize('D',$_[0]);

  # Remove character properties
  $norm =~ s/\p{InCombiningDiacriticalMarks}//g;

  # Deal with some special cases ...
  $norm =~ tr/ıŁłđĐÐØø/iLldDDOo/;
  return normalize('C', $norm);
};


sub _list_props {
  my $string = shift;
  use Unicode::Properties 'uniprops';
  foreach (split('', normalize('D', $string))) {
    print ord($_) . ': ' . join(', ', uniprops($_)), "\n";
  };
};


# Normalize to KC form
sub normalize_nfkc {
  return normalize('KC',$_[0]);
};


# From Mojo::Util
sub squote {
  my $str = shift;
  $str =~ s/(['\\])/\\$1/g;
  return qq{'$str'};
};


# From Mojo::Util
sub unsquote {
  my $str = shift;
  return $str unless $str =~ s/^'(.*)'$/$1/g;
  $str =~ s/\\\\/\\/g;
  $str =~ s/\\'/'/g;
  return $str;
};


# Accepts a possible binary value
# and returns a shortened b64 encoding.
# In case the value looks like a number,
# the number is returned.
# In case the value is undefined, a '-'
# is returned.
sub binary_short {
  my $v = shift;
  return '-' unless defined $v;
  return $v if looks_like_number($v);
  return substr(b64_encode($v), 0, 3) . '..' . substr(b64_encode($v), -4,3);
};

1;
