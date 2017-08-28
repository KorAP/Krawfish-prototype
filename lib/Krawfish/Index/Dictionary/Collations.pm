package Krawfish::Index::Dictionary::Collations;
use Krawfish::Index::Dictionary::Collation;
use strict;
use warnings;

# Get the collation based on the locale
# This currently does not support collation ids!
sub new {
  my $class = shift;

  # Store collations as locales
  bless {}, $class;
};


# Get collation
sub get {
  my ($self, $locale) = @_;
  return $self->{$locale} //= Krawfish::Index::Dictionary::Collation->new($locale);
};


1;
