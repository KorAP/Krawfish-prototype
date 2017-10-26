package Krawfish::Compile::Segment::Aggregate::Values;
use parent 'Krawfish::Compile::Segment::Aggregate::Base';
use Krawfish::Koral::Result::Aggregate::Values;
use Krawfish::Log;
use strict;
use warnings;

# TODO:
#   Rename to FieldCalc or FieldSum

# TODO:
#   Support corpus classes

# TODO:
#   This is rather a group query or better:
#   An aggregation on groups!

use constant {
  DEBUG => 0
};

sub new {
  my $class = shift;
  my $self = bless {
    fields_obj => shift,

    # This needs to be numerical field ids!
    field_ids =>  [map { ref($_) ? $_->term_id : $_ } @{shift()}],
  }, $class;

  # Initialize aggregator
  $self->{result} = Krawfish::Koral::Result::Aggregate::Values->new(
    $self->{field_ids}
  );

  return $self;
};


# Initialize field pointer
sub _init {
  return if $_[0]->{field_pointer};

  my $self = shift;

  $self->{field_pointer} = $self->{fields_obj}->pointer;
};


# Release for each doc
sub each_doc {
  my ($self, $current, $result) = @_;

  $self->_init;

  if (DEBUG) {
    print_log('aggr_values', 'Aggregate on field values');
  };

  # Get current document
  my $doc_id = $current->doc_id;

  my $pointer = $self->{field_pointer};

  # Get aggregation information
  my $aggr = $self->{result};

  # Move fields pointer to current document
  if ($pointer->skip_doc($doc_id) == $doc_id) {

    # collect values
    my @values = $pointer->int_fields(@{$self->{field_ids}}) or return;

    # Aggregate all values
    foreach my $field (@values) {

      # Aggregate value
      $aggr->add($field->key_id, $field->value);
    };
  };
};


# Result
sub result {
  $_[0]->{result};
};


# Stringification
sub to_string {
  return 'values:' . join(',', @{$_[0]->{field_ids}});
};


1;
