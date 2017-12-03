package Krawfish::Koral::Result;
use Role::Tiny::With;
with 'Krawfish::Koral::Report';
with 'Krawfish::Koral::Result::Inflatable';
use strict;
use warnings;

# TODO:
# It may be beneficial to have
# - Aggregate
# - Group
# - Sort
# - Enrich
# on the same level as query and corpus
# and remove the intermediate compile
# directive!

# Constructor
sub new {
  my $class = shift;
  bless {
    group       => undef,
    aggregation => [],
    matches     => []
  }, $class;
};


# Add matches to the result
sub add_match {
  my ($self, $match) = @_;
  push @{$self->{matches}}, $match;
};


# Get list of matches
sub matches {
  $_[0]->{matches};
};


# Add aggregated information
sub add_aggregation {
  my ($self, $aggregation) = @_;

  push(@{$self->{aggregation}}, $aggregation);
};


# Merge aggregation
sub merge_aggregation {
  my ($self, $result) = @_;

  my $aggregates = $self->{aggregation};

  # Check all aggregations
  AGGR: foreach my $new_aggr (@{$result->{aggregation}}) {

    # Merge with existing aggregation
    foreach my $est_aggr (@$aggregates) {

      # Merge new aggregations with established aggregations
      if ($new_aggr->key eq $est_aggr->key) {

        # Merge
        $est_aggr->merge($new_aggr);
        next AGGR;
      };
    };

    # Introduce aggregation
    $self->add_aggregation($new_aggr);
  };

  return;
};


# Get aggregations
sub aggregation {
  $_[0]->{aggregation};
};


# Get or set group results
sub group {
  my $self = shift;
  if (@_) {
    $self->{group} = shift;
    return $self;
  };

  $self->{group};
};


# Stringification
sub to_string {
  my ($self, $id) = @_;
  my $str = '';

  # Add aggregation
  if (@{$self->{aggregation}}) {
    $str .= '[aggr=';
    foreach (@{$self->{aggregation}}) {
      $str .= $_->to_string($id);
    };
    $str .= ']';
  };

  # Create matches
  if (@{$self->{matches}}) {
    $str .= '[matches=';
    foreach (@{$self->{matches}}) {
      $str .= $_->to_string($id);
    };
    $str .= ']';
  };

  if ($self->group) {
    $str .= '[group=';
    $str .= $self->group->to_string($id);
    $str .= ']';
  };

  return $str;
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

  if ($self->group) {
    $self->group->inflate($dict);
  };

  $self;
};


# Get koral result fragment
sub to_koral_fragment {
  my $self = shift;
  my $result = {
    '@type' => 'koral:result',
  };

  # Add aggregation
  if (@{$self->{aggregation}}) {
    # It is beneficial to be able to point to,
    # e.g. the field frequencies without iterating
    # through all aggregations.
    # Therefor it is probably better to use the ->key
    # to add aggregations instead of arrays.

    my %aggr = ();
    foreach (@{$self->{aggregation}}) {
      $aggr{$_->key} = $_->to_koral_fragment;
    };

    $result->{aggregation} = \%aggr;
  };

  # Add matches
  if (@{$self->{matches}}) {
    my @matches = ();
    foreach (@{$self->{matches}}) {
      push @matches, $_->to_koral_fragment;
    };

    $result->{matches} = \@matches;
  };

  if ($self->{group}) {
    $result->{group} = $self->group->to_koral_fragment
  };

  return $result;
};


1;

__END__
