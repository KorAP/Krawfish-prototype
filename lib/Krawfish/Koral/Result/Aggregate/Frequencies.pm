package Krawfish::Koral::Result::Aggregate::Frequencies;
use strict;
use warnings;
use Role::Tiny::With;
use Krawfish::Koral::Result::Aggregate::Length;
use Krawfish::Util::Bits;

with 'Krawfish::Koral::Result::Inflatable';
with 'Krawfish::Koral::Result::Aggregate';

# TODO:
#   requires a merge() method

# This calculates frequencies for all corpus classes

# TODO:
#   Instead of keys a bit-trie or a list may in the end
#   be the most efficient data structure.
#   This should probably be abstracted and used by all
#   Aggregate objects.

# Constructor
sub new {
  my $class = shift;
  bless {
    flags => shift,
    freqs => {},
    classes => undef
  }, $class;
};


sub key {
  'frequencies';
};


# Increment value per document
sub incr_doc {
  my ($self, $flags) = @_;
  my $freq = ($self->{freqs}->{$flags} //= [0,0]);
  $freq->[0]++;
};


# Increment value per document
sub incr_match {
  my ($self, $flags) = @_;
  my $freq = ($self->{freqs}->{$flags} //= [0,0]);
  $freq->[1]++;
};


# Merge results
sub merge {
  my ($self, $aggr) = @_;

  foreach my $new_flags (keys %{$aggr->{freqs}}) {
    $self->{freqs}->{$new_flags} //= [0,0];
    $self->{freqs}->{$new_flags}->[0] += $aggr->{freqs}->{$new_flags}->[0];
    $self->{freqs}->{$new_flags}->[1] += $aggr->{freqs}->{$new_flags}->[1];
  };
};


# Inflate result
sub inflate {
  $_[0];
};


# Get class ordering
sub _to_classes {
  my $self = shift;

  my $freqs = $self->{freqs};

  my @classes;
  # Iterate over all frequency combinations
  foreach my $key (keys %$freqs) {

    # Iterate over all classes in this combination
    foreach my $class (flags_to_classes($key)) {
      $classes[$class] //= [0,0];
      $classes[$class]->[0] += $freqs->{$key}->[0];
      $classes[$class]->[1] += $freqs->{$key}->[1];

      # Alternatively store in [$_ * 2] and [$_ * 2 + 1]
    };

  };

  return \@classes;
};


# Stringification
sub to_string {
  my $self = shift;
  my $str = '[freq=';

  my @classes = @{$self->_to_classes};

  my $first = 0;
  foreach (my $i = 0; $i < @classes; $i++) {
    $str .= $i == 0 ? 'total' : 'inCorpus-' . $i;
    $str .= ':[' . $classes[$i]->[0] . ',' .  $classes[$i]->[1] . ']';
    $str .= ';';
  };
  chop($str);
  return $str . ']';
};


# Serialize to KQ
sub to_koral_fragment {
  my $self = shift;
  my $aggr = {
    '@type' => 'koral:aggregation',
    'aggregation' => 'aggregation:frequencies'
  };

  my @classes = @{$self->_to_classes};
  my $first = 0;
  foreach (my $i = 0; $i < @classes; $i++) {
    $aggr->{$i == 0 ? 'total' : 'inCorpus-' . $i} = {
      docs => $classes[$i]->[0],
      matches => $classes[$i]->[1]
    };
  };

  return $aggr;
};


1;
