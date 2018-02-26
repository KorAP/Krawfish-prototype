package Krawfish::Koral::Result::Group::Aggregates;
use Krawfish::Koral::Result::Group::Aggregate;
use strict;
use warnings;

# Store and retrieve group objects based on group definitions
# This is an intermediate to Group::Aggregate

# Constructor
sub new {
  my $class = shift;
  bless {}, $class;
};

# Convert a group definition to a signature
sub group_to_sig {
  my $group = shift;
  join('_', @$group);
};


# Convert a signature to a group definition
sub sig_to_group {
  my $sig = shift;
  return [split('_', $sig)];
};


# Return a list of criteria
# Accepts a list of pattterns, see Krawfish::Util::PatternList
sub aggregates {
  my ($self, $pattern_list) = @_;

  # In case the pattern is null, return a
  # default object, otherwise one, that is
  # based on a pattern.
  my @aggrs = ();
  foreach (@$pattern_list) {

    # Get a signature of the group
    my $sig = group_to_sig($_);

    # Aggregation group not initialized yet
    unless (exists $self->{$sig}) {
      $self->{$sig} = Krawfish::Koral::Result::Group::Aggregate->new;
    };

    # Push to list
    push @aggrs, $self->{$sig};
  };

  return \@aggrs;
};



1;
