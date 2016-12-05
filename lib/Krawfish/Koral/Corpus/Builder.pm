package Krawfish::Koral::Corpus::Builder;
use Krawfish::Koral::Corpus::Field;
use Krawfish::Koral::Corpus::FieldGroup;
use Krawfish::Query::Nothing;
use Krawfish::Koral::Corpus::Cache;
use strict;
use warnings;

sub new {
  my $class = shift;
  bless \(my $self = ''), $class;
};

# Create 'and' group
sub field_and {
  shift;
  return Krawfish::Koral::Corpus::FieldGroup->new('and', @_);
};

# Create 'or' group
sub field_or {
  shift;
  return Krawfish::Koral::Corpus::FieldGroup->new('or', @_);
};

# Create 'string' field
sub string {
  shift;
  return Krawfish::Koral::Corpus::Field->new('string', @_);
};

# Create 'date' field
sub date {
  shift;
  return Krawfish::Koral::Corpus::Field->new('date', @_);
};

# Create 'integer' field
sub regex {
  shift;
  return Krawfish::Koral::Corpus::Field->new('regex', @_);
};

# No match
sub nothing {
  Krawfish::Query::Nothing->new;
};


# Cache the result
sub cache {
  shift;
  return Krawfish::Koral::Corpus::Cache->new(@_);
};

1;

__END__
