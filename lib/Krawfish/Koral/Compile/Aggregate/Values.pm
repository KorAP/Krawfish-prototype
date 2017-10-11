package Krawfish::Koral::Compile::Aggregate::Values;
use Krawfish::Compile::Segment::Aggregate::Values;
use strict;
use warnings;


# Constructor
# Accepts a list of numerical key objects
sub new {
  my $class = shift;
  bless [@_], $class;
};


sub type {
  'values'
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

  # Sort field ids in ascending order!
  @{$self} = sort { $a->term_id <=> $b->term_id } @identifier;

  return $self;
};


sub to_string {
  # warn 'DEPRECATED'
  my $self = shift;
  return 'values:[' . join(',', map { $_->to_string } @$self) . ']';
};


sub to_id_string {
  my $self = shift;
  return 'values:[' . join(',', map { $_->to_id_string } @$self) . ']';
};

sub to_term_string {
  my $self = shift;
  return 'values:[' . join(',', map { $_->to_term_string } @$self) . ']';
};


sub optimize {
  my ($self, $segment) = @_;

  return Krawfish::Compile::Segment::Aggregate::Values->new(
    $segment->fields,
    [$self->operations]
  );
};



1;
