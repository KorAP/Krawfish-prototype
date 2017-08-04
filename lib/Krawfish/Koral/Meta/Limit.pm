package Krawfish::Koral::Meta::Limit;
use Krawfish::Koral::Meta::Node::Limit;
use strict;
use warnings;

use constant ITEMS_PER_PAGE => 20;

sub new {
  my $class = shift;
  bless {
    start_index    => shift // 0,
    items_per_page => shift // ITEMS_PER_PAGE
  }, $class;
};


sub items_per_page {
  $_[0]->{items_per_page};
};

sub start_index {
  $_[0]->{start_index};
};


sub type {
  'limit';
};


# Create a limit query
sub wrap {
  my ($self, $query) = @_;

  return Krawfish::Koral::Meta::Node::Limit->new(
    $query,
    $self->start_index,
    $self->items_per_page
  );
};


# Normalize limit
sub normalize {
  $_[0];
};


sub to_string {
  my $self = shift;
  return 'limit=[' . $self->start_index . '-'.
    ($self->start_index + $self->items_per_page) . ']';
};

1;
