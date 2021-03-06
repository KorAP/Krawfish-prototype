package Krawfish::Koral::Compile::Aggregate::Fields;
use Krawfish::Compile::Segment::Aggregate::Fields;
use strict;
use warnings;

# TODO:
#   Remember order of fields

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
  @{$self} = sort { $a->{term_id} <=> $b->{term_id} } @identifier;

  return $self;
};


sub optimize {
  my ($self, $segment) = @_;

  return Krawfish::Compile::Segment::Aggregate::Fields->new(
    $segment->fields,
    [$self->operations]
  );
};


sub to_string {
  my ($self, $id) = @_;
  return 'fields:[' . join(',', map { defined $_ ? $_->to_string($id) : '?' } @$self) . ']';
};


1;
