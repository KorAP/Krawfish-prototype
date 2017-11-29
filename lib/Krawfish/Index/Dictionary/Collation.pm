package Krawfish::Index::Dictionary::Collation;
use Unicode::Collate::Locale;
use strict;
use warnings;

# This is just a convenience wrapper for Unicode::Collate::Locale

# Constructor
sub new {
  my ($class, $locale) = @_;

  # Create collation object (may be lazy loaded)
  my $coll = Unicode::Collate::Locale->new(
    locale => $locale,
    normalization => undef
  );

  bless \$coll, $class;
};


# Get sort key for value
sub sort_key {
  my ($self, $value) = @_;
  return $$self->getSortKey($value);
};

# TODO:
#   Introduce
#   - lt()
#   - cmp()

1;
