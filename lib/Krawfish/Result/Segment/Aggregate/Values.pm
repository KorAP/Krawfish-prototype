package Krawfish::Result::Segment::Aggregate::Values;
use parent 'Krawfish::Result::Segment::Aggregate::Base';
use Krawfish::Log;
use strict;
use warnings;

# TODO: Rename to FieldCalc or FieldSum

use constant {
  DEBUG          => 0,
  MIN_INIT_VALUE => 32_000
};

sub new {
  my $class = shift;
  my $index = shift;
  my $self = bless {
    index => $index, # Index

    # This need to be a numerical fields!
    fields => shift,
    # TODO: May need to be translated into field_term_ids

    # TODO:
    #   It may be more efficient to store a list of numerical
    #   field values here (e.g. sentence)
    fields_obj  => $index->fields,
    aggregate => {}
  }, $class;

  # Initiate aggregation maps
  foreach (@{$self->{fields}}) {
    $self->{aggregate}->{$_} = {
      min   => MIN_INIT_VALUE,
      max   => 0,
      sum   => 0,
      freq => 0
    };
  };

  return $self;
};


# Release for each doc
sub each_doc {
  my ($self, $current, $result) = @_;

  my $fields = $self->{fields_obj};

  # my $value_current = $values->current;

  # Current value has to catch up to the current doc
  # if ($value_current->doc_id < $current->doc_id) {

    # Skip to the requested doc_id (or beyond)
    # $value_current = $values->skip_doc($current->doc_id);
  # };

  # Get document fields
  my $doc_fields = $fields->get($current->doc_id);

  # Get aggregation information
  my $aggr = $self->{aggregate};

  foreach my $field (@{$self->{fields}}) {

    # Get field value
    my $value = $doc_fields->{$field};

    next unless defined $value;

    # Get field in aggregation
    my $field_aggr = $aggr->{$field};

    $field_aggr->{min} = $field_aggr->{min} < $value ? $field_aggr->{min} : $value;
    $field_aggr->{max} = $field_aggr->{max} > $value ? $field_aggr->{max} : $value;
    $field_aggr->{sum} += $value;
    $field_aggr->{freq}++;
  };
};


# Stringification
sub to_string {
  return 'values:' . $_[0]->{field};
};


# Finish the aggregation
sub on_finish {
  my ($self, $result) = @_;
  my $aggr = ($result->{aggregate} = $self->{aggregate});
  foreach (values %{$aggr}) {
    next unless $_->{freq};
    $_->{avg} = $_->{sum} / $_->{freq};
  };
};

1;
