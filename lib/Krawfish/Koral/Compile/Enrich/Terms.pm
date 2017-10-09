package Krawfish::Koral::Compile::Enrich::Terms;
use Krawfish::Koral::Compile::Node::Enrich::Terms;
use List::MoreUtils qw/uniq/;
use strict;
use warnings;

# Collect term ids per class

sub new {
  my $class = shift;
  bless [@_], $class;
};

sub type {
  'terms';
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


# Remove duplicate classes and
# order numerically
sub normalize {
  my $self = shift;
  @$self = reverse sort uniq @$self;
  return $self;
};


# Create single query tree
sub wrap {
  my ($self, $query) = @_;
  return Krawfish::Koral::Compile::Node::Enrich::Terms->new(
    $query,
    [$self->operations]
  );
};


sub to_string {
  my $self = shift;
  return 'terms:['.join(',', @$self).']';
};

1;
