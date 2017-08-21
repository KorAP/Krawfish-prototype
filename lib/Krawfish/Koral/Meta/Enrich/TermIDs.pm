package Krawfish::Koral::Meta::Enrich::TermIDs;
use Krawfish::Koral::Meta::Node::Enrich::TermIDs;
use List::MoreUtils qw/uniq/;
use strict;
use warnings;

# Collect term ids per class

sub new {
  my $class = shift;
  bless [@_], $class;
};

sub type {
  'termids';
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
  return Krawfish::Koral::Meta::Node::Enrich::TermIDs->new(
    $query,
    [$self->operations]
  );
};


sub to_string {
  my $self = shift;
  return 'termids:['.join(',', @$self).']';
};

1;
