package Krawfish::Koral::Corpus::Builder;
use strict;
use warnings;
use Krawfish::Koral::Corpus::Field;
use Krawfish::Koral::Corpus::Field::String;
use Krawfish::Koral::Corpus::Field::Date;
use Krawfish::Koral::Corpus::Field::DateString;
use Krawfish::Koral::Corpus::Field::Regex;
use Krawfish::Koral::Corpus::Field::Integer;
use Krawfish::Koral::Corpus::FieldGroup;
use Krawfish::Koral::Corpus::Class;
use Krawfish::Koral::Corpus::Nowhere;
use Krawfish::Koral::Corpus::Cache;
use Krawfish::Koral::Corpus::AndNot;
use Krawfish::Koral::Corpus::Span;

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


# Create 'anywhere' aka matchall query
sub anywhere {
  shift;
  Krawfish::Koral::Corpus::Anywhere->new;
};


# Create 'null' aka ignorable query
sub null {
  shift;
  my $null = Krawfish::Koral::Corpus::FieldGroup->new('or');
  $null->is_null(1);
  $null;
};


# Create 'nowhere' query
sub nowhere {
  Krawfish::Koral::Corpus::Nowhere->new;
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
  return Krawfish::Koral::Corpus::Field::String->new(@_);
};

# Create 'date_string' field as partial
# This is for in
sub date_string {
  shift;
  return Krawfish::Koral::Corpus::Field::DateString->new(@_);
};


# Create span query
sub span {
  shift;
  return Krawfish::Koral::Corpus::Span->new(@_);
};

# Create 'date' field
# May be renamed to 'field_date'
sub date {
  shift;
  return Krawfish::Koral::Corpus::Field::Date->new(@_);
};

# Create 'integer' field
# May be renamed to 'field_integer'
sub integer {
  shift;
  return Krawfish::Koral::Corpus::Field::Integer->new(@_);
};

# Create 'regex' field
# May be renamed to 'field_re'
sub regex {
  shift;
  return Krawfish::Koral::Corpus::Field::Regex->new(@_);
};


# Refer to the primary instance of the doc
sub primary_node {
  Krawfish::Koral::Corpus::Field::String->new('__1');
};


# Refer to the replicant instance of the doc
sub replicant_node {
  shift;
  Krawfish::Koral::Corpus::Field::String->new('__2:' . shift);
};


# Match all docs that have a certain field associated with
sub existent {
  my ($self, $field) = @_;

  # This should either use rankings or (if not defined) fields
  # directly (although this will probably be slow).
  # Therefore it will also work with "attachement" fields.
  ...
};


# Cache the VC result or get the VC result from cache
sub cache {
  shift;
  return Krawfish::Koral::Corpus::Cache->new(@_);
};

1;

__END__
