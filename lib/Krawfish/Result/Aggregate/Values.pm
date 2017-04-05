package Krawfish::Result::Aggregate::Values;
use Krawfish::Log;
use strict;
use warnings;

# TODO: Rename to FieldCount

use constant DEBUG => 0;

sub new {
  my $class = shift;
  bless {
    index => shift, # Index

    # This needs to be a numerical field!
    field => shift, # Field name

    list  => undef, # List of numerical field values (e.g. sentence)

    # Init values
    min   => 32_000,
    max   => 0,
    sum   => 0,
    count => 0
  }, $class;
};


# Initialize aggregation
sub _init {
  return if $_[0]->{list};

  my $self = shift;

  # Get numerical field values for this field
  $self->{list} =  $self->{index}->field_values($self->{field});
};


# Release for each doc
sub each_doc {
  my ($self, $current) = @_;

  $self->_init;

  my $values = $self->{list};
  my $value_current = $values->current;

  # Current value has to catch up to the current doc
  if ($value_current->doc_id < $current->doc_id) {

    # Skip to the requested doc_id (or beyond)
    $value_current = $values->skip_doc($current->doc_id);
  };

  if ($value_current->doc_id == $current->doc_id) {
    my $value = $value_current->value;
    $self->{min} = $self->{min} < $value ? $self->{min} : $value;
    $self->{max} = $self->{max} > $value ? $self->{max} : $value;
    $self->{sum} += $value;
    $self->{count}++;
  };
};

sub each_match {};

sub to_string {
  return 'values:' . $_[0]->{field};
}

sub result {
  my $self = shift;
  return if $self->{count} == 0;
  return {
    aggregate => {
      $self->{field} => {
        min => $self->{min},
        max => $self->{max},
        sum => $self->{sum},
        count => $self->{count},
        avg => $self->{sum} / $self->{count}
      }
    }
  };
};

1;
