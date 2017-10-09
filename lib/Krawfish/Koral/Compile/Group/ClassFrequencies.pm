package Krawfish::Koral::Compile::Group::ClassFrequencies;
use List::Util qw/uniq/;
use Krawfish::Koral::Compile::Node::Group::ClassFrequencies;
use strict;
use warnings;


# Accepts classes
sub new {
  my $class = shift;
  bless [@_], $class;
};


sub type {
  'class_freq'
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
  @$self = uniq @$self;
  return $self;
};


sub wrap {
  my ($self, $query) = @_;
  return Krawfish::Koral::Compile::Node::Group::ClassFrequencies->new(
    $query,
    [$self->operations]
  )
};


#sub identify {
#  $_[0];
#};


sub to_string {
  my $self = shift;
  return 'classFreq:[' . join(',', @$self) . ']';
};


sub optimize {
  ...
};

1;
