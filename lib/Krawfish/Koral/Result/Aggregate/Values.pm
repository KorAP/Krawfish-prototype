package Krawfish::Koral::Result::Aggregate::Values;
use strict;
use warnings;
use Role::Tiny::With;
use Krawfish::Util::Bits;
use Krawfish::Log;
use Data::Dumper;

with 'Krawfish::Koral::Result::Inflatable';
with 'Krawfish::Koral::Result::Aggregate';

# Support of classes is relevant, e.g. to compare the size
# of subcorpora.
# Example:
#   What's the difference between a corpus and a rewritten
#   corpus in regards to number of sentences.

use constant {
  MIN_INIT_VALUE => 32_000,
  DEBUG => 0
};

sub new {
  my $class = shift;
  my $self = bless {
    field_ids => shift,
    flags => shift,
    values => {},
    field_terms => undef
  }, $class;

  # Initiate aggregation maps for each field
  foreach (@{$self->{field_ids}}) {
    $self->{values}->{$_} = {};
  };

  return $self;
};

sub key {
  'values';
};


# Merge aggregation results on node level
sub merge {
  my ($self, $aggr) = @_;

  if (DEBUG) {
    print_log(
      'k_r_a_values',
      'Aggr: ' . Dumper($self),
      'New: ' . Dumper($aggr));
  };


  my $value = ($self->{values} //= {});

  # Iterate over all fields
  foreach my $field (keys %{$aggr->{values}}) {

    $value = ($value->{$field} //= {});

    # Iterate over flags
    foreach my $flag (keys %{$aggr->{values}->{$field}}) {

      if (DEBUG) {
        print_log('k_r_a_values', 'Merge #' . $field . ':' . $flag);
      };

      # Get flag fvalue
      my $a_flag = $aggr->{values}->{$field}->{$flag};

      if (!exists $value->{$flag} || !defined $value->{$flag}->{min}) {

        # Set flag
        $value->{$flag} = {
          min => $a_flag->{min},
          max => $a_flag->{max},
          sum => $a_flag->{sum},
          freq => $a_flag->{freq}
        };

        if (DEBUG) {
          print_log('k_r_a_values', 'a: ' . Dumper $a_flag);
        };
      }
      else {

        if (DEBUG) {
          print_log('k_r_a_values', 'b: ' . Dumper $a_flag);
        };

        my $l_flag = $value->{$flag};
        $l_flag->{min} = $a_flag->{min} < $l_flag->{min} ? $a_flag->{min} : $l_flag->{min};
        $l_flag->{max} = $a_flag->{max} > $l_flag->{max} ? $a_flag->{max} : $l_flag->{max};
        $l_flag->{sum} += $a_flag->{sum};
        $l_flag->{freq} += $a_flag->{freq};
      };
    };
  };
};


# Add field value to field sum
sub incr_doc {
  my ($self, $field_id, $value, $flags) = @_;

  # Get field of interest
  my $aggr = $self->{values}->{$field_id};

  my $aggr_flag = $aggr->{$flags} //= {
    min  => MIN_INIT_VALUE,
    max  => 0,
    sum  => 0,
    freq => 0
  };

  $aggr_flag->{min} = $aggr_flag->{min} < $value ? $aggr_flag->{min} : $value;
  $aggr_flag->{max} = $aggr_flag->{max} > $value ? $aggr_flag->{max} : $value;
  $aggr_flag->{sum} += $value;
  $aggr_flag->{freq}++;
};


# Inflate result
sub inflate {
  my ($self, $dict) = @_;

  my $values = $self->{values};

  my %values;
  foreach my $field_id (keys %{$values}) {

    my $field_term = $dict->term_by_term_id($field_id);

    # Remove the term marker
    # TODO:
    #   this may be a direct feature of the dictionary instead
    # $field_term =~ s/^!//;
    $field_term = substr($field_term, 1); # ~ s/^!//;
    $values{$field_term} = $values->{$field_id};
  };

  $self->{field_terms} = \%values;
  return $self;
};


# This will return the class view and calculate average
sub _to_classes {
  my $self = shift;

  my @classes;

  my $values = $self->{field_terms};

  if (DEBUG) {
    print_log('k_r_values', 'Make classes');
  };

  # Iterate over values
  foreach my $field (keys %$values) {

    if (DEBUG) {
      print_log('k_r_values', 'Field is ' . $field);
    };

    my $flags = $values->{$field};

    # Iterate over flags
    foreach my $flag (keys %$flags) {

      if (DEBUG) {
        print_log('k_r_values', 'Flag is ' . $flag . '|' . bitstring($flag));
      };


      # Iterate over classes
      foreach my $class (flags_to_classes($flag)) {

        $classes[$class] //= {};

        # Get freqency
        my $freq = ($classes[$class]->{$field} //= {
          min  => MIN_INIT_VALUE,
          max  => 0,
          sum  => 0,
          freq => 0
        });
        my $value = $flags->{$flag};
        $freq->{sum} += $value->{sum};
        $freq->{freq} += $value->{freq};
        $freq->{min} = (
          $value->{min} < $freq->{min} ? $value->{min} : $freq->{min}
        );
        $freq->{max} = (
          $value->{max} > $freq->{max} ? $value->{max} : $freq->{max}
        );

        # Calculate average value
        $freq->{avg} = $freq->{sum} / $freq->{freq};
      };
    };
  };

  return \@classes;
};


# Stringification
sub to_string {
  my ($self, $ids) = @_;

  my $str = '[values=';

  # IDs not supported
  if ($ids) {
    # warn 'ID based stringification currently not supported';
    return $str . '#?]';
  };

  # No terms yet
  unless ($self->{field_terms}) {
    # warn 'ID based stringification currently not supported';
    return $str . '#?]';
  };


  my @classes = @{$self->_to_classes};
  my $first = 0;
  foreach (my $i = 0; $i < @classes; $i++) {
    $str .= $i == 0 ? 'total' : 'inCorpus-' . $i;
    $str .= ':[';

    my $values = $classes[$i];

    foreach my $field (sort keys %$values) {
      $str .= $field . ':';

      my $values = $values->{$field};

      $str .= '[';
      $str .= 'sum:' . $values->{sum} . ',';
      $str .= 'freq:' . $values->{freq} . ',';
      $str .= 'min:' . $values->{min} . ',';
      $str .= 'max:' . $values->{max} . ',';
      $str .= 'avg:' . $values->{avg};
      $str .= '];';
    };
    chop $str;
    $str .= '];';
  };
  chop $str;
  $str .= ']';

  return $str;
};


sub to_koral_fragment {
  my $self = shift;
  my $aggr = {
    '@type' => 'koral:aggregation',
    'aggregation' => 'aggregation:values'
  };

  my @classes = @{$self->_to_classes};
  my $first = 0;
  foreach (my $i = 0; $i < @classes; $i++) {
    my $val = $aggr->{$i == 0 ? 'total' : 'inCorpus-' . $i} = {};
    my $values = $classes[$i];

    foreach my $field (sort keys %$values) {
      my $values = $values->{$field};

      # Set values per field
      $val->{$field} = {
        'sum'  => $values->{sum},
        'freq' => $values->{freq},
        'min'  => $values->{min},
        'max'  => $values->{max},
        'avg'  => $values->{avg}
      };
    };
  };

  return $aggr;
};


1;
