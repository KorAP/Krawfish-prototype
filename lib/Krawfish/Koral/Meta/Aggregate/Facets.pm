package Krawfish::Koral::Meta::Aggregate::Facets;
use strict;
use warnings;

# TODO:
#   Rename to 'Fields'

sub new {
  my $class = shift;
  bless [@_], $class;
};


sub type {
  'facets'
};


# Get or set operations
sub operations {
  my $self = shift;
  if (@_) {
    @$self = @_;
    return $self;
  };
  return @$self;
};


# Remove duplicates
sub normalize {
  my $self = shift;
  my @unique;
  my %unique;
  foreach (@$self) {
    unless (exists $unique{$_->to_string}) {
      push @unique, $_;
      $unique{$_->to_string} = 1;
    };
  };
  @$self = @unique;
  return $self;
};


# TODO:
#   Create one facet wrapping each other!
#   OR as fields are sorted in order, fetching multiple
#   fields for a document at once may be beneficial
sub wrap {
  ...
};


sub identify {
  my ($self, $dict) = @_;

  my @identifier;
  foreach (@$self) {

    # Field may not exist in dictionary
    my $field = $_->identify($dict);
    if ($field) {
      push @identifier, $field;
    };
  };

  return unless @identifier;

  @{$self} = @identifier;

  return $self;
};


sub to_string {
  my $self = shift;
  return 'facets:[' . join(',', map { $_->to_string } @$self) . ']';
};

1;
