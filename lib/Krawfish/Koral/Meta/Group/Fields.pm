package Krawfish::Koral::Meta::Group::Fields;
use Krawfish::Koral::Meta::Node::Group::Fields;
use strict;
use warnings;

# This is pretty much identical to Aggregate::Facets!


# Accepts fields
sub new {
  my $class = shift;
  bless [@_], $class;
};


sub type {
  'fields'
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


sub wrap {
  my ($self, $query) = @_;
  return Krawfish::Koral::Meta::Node::Group::Fields->new(
    $query,
    [$self->operations]
  )
};


#sub identify {
#  my ($self, $dict) = @_;
#
#  my @identifier;
#  foreach (@$self) {
#
#    # Field may not exist in dictionary
#    my $field = $_->identify($dict);
#    if ($field) {
#      push @identifier, $field;
#    };
#  };
#
#  return unless @identifier;
#
#  @{$self} = @identifier;
#
#  return $self;
#};


sub to_string {
  my $self = shift;
  return 'fields:[' . join(',', map { $_->to_string } @$self) . ']';
};

sub optimize {
  ...
};

1;
