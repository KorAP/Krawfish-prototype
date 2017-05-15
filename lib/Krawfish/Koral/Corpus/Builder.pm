package Krawfish::Koral::Corpus::Builder;
use Krawfish::Koral::Corpus::Field;
use Krawfish::Koral::Corpus::FieldGroup;
use Krawfish::Koral::Corpus::Class;
use Krawfish::Koral::Corpus::Nothing;
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

sub any {
  shift;
  my $any = Krawfish::Koral::Corpus::FieldGroup->new('or');
  $any->is_any(1);
  $any;
};

sub null {
  shift;
  my $null = Krawfish::Koral::Corpus::FieldGroup->new('or');
  $null->is_null(1);
  $null;
};

# No match
sub nothing {
  Krawfish::Koral::Corpus::Nothing->new;
};


sub class {
  shift;
  return Krawfish::Koral::Corpus::Class->new(@_);
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

# Cache the result
sub cache {
  shift;
  return Krawfish::Koral::Corpus::Cache->new(@_);
};

1;

__END__
