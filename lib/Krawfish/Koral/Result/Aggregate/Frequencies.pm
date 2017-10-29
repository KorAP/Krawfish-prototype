package Krawfish::Koral::Result::Aggregate::Frequencies;
use Krawfish::Koral::Result::Aggregate::Length;
use Krawfish::Util::Bits;
use strict;
use warnings;

# This calculates frequencies for all classes

# TODO:
#   Instead of keys a byte-trie may in the end
#   be the most efficient data structure.

# Constructor
sub new {
  my $class = shift;
  bless {
    flags => shift,
    freqs => {},
    classes => undef
  }, $class;
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


# Inflate result
sub inflate {
  $_[0];
};


# Finish the calculation
sub on_finish {
  $_[0]
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
    $str .= $i == 0 ? 'total' : 'inCorpus' . $i;
    $str .= ':[' . $classes[$i]->[0] . ',' .  $classes[$i]->[1] . ']';
    $str .= ';';
  };
  chop($str);
  return $str . ']';
};


sub key {
  'frequencies';
};

1;
