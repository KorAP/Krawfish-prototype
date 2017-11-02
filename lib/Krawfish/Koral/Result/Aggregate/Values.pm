package Krawfish::Koral::Result::Aggregate::Values;
use strict;
use warnings;
use Role::Tiny::With;
use Krawfish::Util::Bits;

with 'Krawfish::Koral::Result::Inflatable';

# Support of classes is relevant, e.g. to compare the size
# of subcorpora.
# Example:
#   What's the difference between a corpus and a rewritten
#   corpus in regards to number of sentences.

use constant {
  MIN_INIT_VALUE => 32_000
};

sub new {
  my $class = shift;
  my $self = bless {
    field_ids => shift,
    flags => shift,
    fields => {},
    field_terms => undef
  }, $class;

  # Initiate aggregation maps for each field
  foreach (@{$self->{field_ids}}) {
    $self->{fields}->{$_} = {};
  };

  return $self;
};

sub key {
  'values';
};


# Add field value to field sum
sub incr_doc {
  my ($self, $field_id, $value, $flags) = @_;

  # Get field of interest
  my $aggr = $self->{fields}->{$field_id};

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

  my $fields = $self->{fields};

  my %fields;
  foreach my $field_id (keys %{$fields}) {

    my $field_term = $dict->term_by_term_id($field_id);

    # Remove the term marker
    # TODO:
    #   this may be a direct feature of the dictionary instead
    # $field_term =~ s/^!//;
    $field_term = substr($field_term, 1); # ~ s/^!//;
    $fields{$field_term} = $fields->{$field_id};
  };

  $self->{field_terms} = \%fields;
  return $self;
};


# This will return the class view and calculate average
sub _to_classes {
  my $self = shift;

  my @classes;

  my $fields = $self->{field_terms};

  # Iterate over fields
  foreach my $field (keys %$fields) {

    my $flags = $fields->{$field};

    # Iterate over flags
    foreach my $flag (keys %$flags) {

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

  # IDs not supported
  if ($ids) {
    warn 'ID based stringification currently not supported';
    return '';
  };

  # No terms yet
  unless ($self->{field_terms}) {
    warn 'ID based stringification currently not supported';
    return '';
  };

  my $str = '[values=';

  my @classes = @{$self->_to_classes};
  my $first = 0;
  foreach (my $i = 0; $i < @classes; $i++) {
    $str .= $i == 0 ? 'total' : 'inCorpus-' . $i;
    $str .= ':[';

    my $fields = $classes[$i];

    foreach my $field (sort keys %$fields) {
      $str .= $field . ':';

      my $values = $fields->{$field};

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
    my $fields = $classes[$i];

    foreach my $field (sort keys %$fields) {
      my $values = $fields->{$field};

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


# Finish the aggregation
sub on_finish {
  $_[0];
};

1;
