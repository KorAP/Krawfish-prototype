package Krawfish::Koral::Result::Aggregate::Values;
use strict;
use warnings;

use constant {
  MIN_INIT_VALUE => 32_000
};

sub new {
  my $class = shift;
  my $self = bless {
    field_ids => shift,
    fields => {},
    field_terms => undef
  }, $class;

  # Initiate aggregation maps
  foreach (@{$self->{field_ids}}) {
    $self->{fields}->{$_} = {
      min   => MIN_INIT_VALUE,
      max   => 0,
      sum   => 0,
      freq => 0
    };
  };

  return $self;
};


# Add field value to field sum
sub add {
  my ($self, $field_id, $value) = @_;

  # Get field of interest
  my $aggr = $self->{fields}->{$field_id};

  $aggr->{min} = $aggr->{min} < $value ? $aggr->{min} : $value;
  $aggr->{max} = $aggr->{max} > $value ? $aggr->{max} : $value;
  $aggr->{sum} += $value;
  $aggr->{freq}++;
};


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


sub to_string {
  my $self = shift;
  if ($self->{field_terms}) {
    my $str = '[values=';

    my $fields = $self->{field_terms};

    foreach my $field (sort keys %$fields) {
      $str .= $field . ':';

      my $values = $fields->{$field};

      $str .= '[';
      $str .= 'sum:' . $values->{sum} . ',';
      $str .= 'freq:' . $values->{freq} . ',';
      $str .= 'min:' . $values->{min} . ',';
      $str .= 'max:' . $values->{max} . ',';
      $str .= 'avg:' . $values->{avg};
      $str .= ']';
      $str .= ';';
    };
    chop $str;

    return $str . ']';
  };


  warn 'Please inflate before!';
  return '';
};


# Finish the aggregation
sub on_finish {
  my $self = shift;

  my $fields = $self->{fields};
  foreach (values %{$fields}) {
    next unless $_->{freq};
    $_->{avg} = $_->{sum} / $_->{freq};
  };
};

1;
