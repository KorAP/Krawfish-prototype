package Krawfish::Koral::Result;
use Role::Tiny::With;
with 'Krawfish::Koral::Info';
use strict;
use warnings;

sub new {
  my $class = shift;
  bless {
    collection  => {},
    aggregation => [],
    matches     => []
  }, $class;
};


# Inflate results
sub inflate {
  my ($self, $dict) = @_;
  foreach (@{$self->matches}) {
    $_->inflate($dict);
  };
  foreach (@{$self->aggregation}) {
    $_->inflate($dict);
  };

  $self;
};

# Add matches to the result
sub add_match {
  my ($self, $match) = @_;
  push @{$self->{matches}}, $match;
};


sub matches {
  $_[0]->{matches};
};

# Add collected information to the head
# TODO:
#   Make this a list as well
# TODO:
#   Rename to compilation
sub add_collection {
  warn 'DEPRECATED';
  my ($self, $collection) = @_;
  $self->{collection} = $collection;
};


# Add aggregated information
sub add_aggregation {
  my ($self, $aggregation) = @_;
  push(@{$self->{aggregation}}, $aggregation);
};


# Get aggregations
sub aggregation {
  $_[0]->{aggregation};
};


sub to_string {
  my $self = shift;
  my $str = '';

  # Add aggregation
  if ($self->{aggregation}) {
    $str .= '[aggr=';
    foreach (@{$self->{aggregation}}) {
      $str .= $_->to_string;
    };
    $str .= ']';
  };

  # Create matches
  if ($self->{matches}) {
    $str .= '[matches=';
    foreach (@{$self->{matches}}) {
      $str .= $_->to_string;
    };
    $str .= ']';
  };

  return $str;
};


# Get koral result fragment
sub to_koral_fragment {
  my $self = shift;
  return {
    '@type' => 'koral:result',

    # TODO:
    #   Rename to 'compilation'
    'collection' => $self->{collection}->to_koral_fragment,
    'matches' => [
      map { $_->to_koral_fragment } @{$self->{matches}}
    ]
  };
};


1;

__END__
