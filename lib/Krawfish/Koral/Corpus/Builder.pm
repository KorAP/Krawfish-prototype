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


# Create 'any' aka matchall query
sub any {
  shift;
  Krawfish::Koral::Corpus::Any->new;
};


# Create 'null' aka ignorable query
sub null {
  shift;
  my $null = Krawfish::Koral::Corpus::FieldGroup->new('or');
  $null->is_null(1);
  $null;
};


# Create 'nothing' query
sub nothing {
  Krawfish::Koral::Corpus::Nothing->new;
};


# Create classed group
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


# Refer to the primary instance of the doc
sub primary_node {
  Krawfish::Koral::Corpus::Field->new('string', '__1');
};


# Refer to the replicant instance of the doc
sub replicant_node {
  shift;
  Krawfish::Koral::Corpus::Field->new('string', '__2:' . shift);
};


# Match all docs that have a certain field associated with
sub existent {
  my ($self, $field) = @_;

  # This should either use rankings or (if not defined) fields
  # directly (although this will probably be slow).
  # Therefore it will also work with "store only" fields.
  ...
};


# Cache the VC result or get the VC result from cache
sub cache {
  shift;
  return Krawfish::Koral::Corpus::Cache->new(@_);
};

1;

__END__
