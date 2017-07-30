package Krawfish::Koral::Corpus::Builder;
use Krawfish::Koral::Corpus::Field;
use Krawfish::Koral::Corpus::FieldGroup;
use Krawfish::Koral::Corpus::Class;
use Krawfish::Koral::Corpus::Nothing;
use Krawfish::Koral::Corpus::Cache;
use Krawfish::Koral::Corpus::AndNot;
use strict;
use warnings;

sub new {
  my $class = shift;
  bless \(my $self = ''), $class;
};

# Create 'and' group
sub bool_and {
  shift;
  return Krawfish::Koral::Corpus::FieldGroup->new('and', @_);
};


# Create 'or' group
sub bool_or {
  shift;
  return Krawfish::Koral::Corpus::FieldGroup->new('or', @_);
};

# Create 'and' group
sub bool_and_not {
  shift;
  return Krawfish::Koral::Corpus::AndNot->new(@_);
};

sub any {
  shift;
  Krawfish::Koral::Corpus::Any->new;
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
# May be renamed to 'field'
sub string {
  shift;
  return Krawfish::Koral::Corpus::Field->new('string', @_);
};

# Create 'date' field
# May be renamed to 'field_date'
sub date {
  shift;
  return Krawfish::Koral::Corpus::Field->new('date', @_);
};

# Create 'regex' field
# May be renamed to 'field_re'
sub regex {
  shift;
  return Krawfish::Koral::Corpus::Field->new('regex', @_);
};

sub primary_node {
  Krawfish::Koral::Corpus::Field->new('string', '__1');
};

sub replicant_node {
  shift;
  Krawfish::Koral::Corpus::Field->new('string', '__2:' shift);
};

# Cache the result
sub cache {
  shift;
  return Krawfish::Koral::Corpus::Cache->new(@_);
};

1;

__END__
