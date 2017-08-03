package Krawfish::Koral::Meta::Enrich::Fields;
use Krawfish::Result::Node::Enrich::Fields;
use strict;
use warnings;

# Define which fields per match should be aggregated

sub new {
  my $class = shift;
  bless [@_], $class;
};

sub type {
  'fields';
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


sub to_string {
  my $self = shift;
  return 'fields=[' . join(',', map { $_->to_string } @$self) . ']';
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

  # Do not return any fields
  return if @identifier == 0;

  @$self = @identifier;

  return $self;
};


# TODO:
#   For the moment, I am not sure where "fields" act
sub to_nodes {
  my ($self, $query) = @_;
  return Krawfish::Result::Node::Enrich::Fields->new($query, [$self->operations]);
};


1;
