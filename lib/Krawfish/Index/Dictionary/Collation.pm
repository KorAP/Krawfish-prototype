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
    UCA_Version => 43,
    locale => ($locale eq 'DE' ? 'de__phonebook' : $locale),
    normalization => undef, # !Should normalize!
    level => 3,
    long_contraction => 1,
    upper_before_lower => undef,
    variable => 'non-ignorable',
  );

  bless \$coll, $class;
};

sub version {
  my $self = shift;
  return $$self->{UCA_Version};
}

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
