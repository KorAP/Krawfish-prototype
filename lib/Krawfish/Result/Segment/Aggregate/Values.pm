package Krawfish::Result::Segment::Aggregate::Values;
use parent 'Krawfish::Result::Segment::Aggregate::Base';
use Krawfish::Posting::Aggregate::Values;
use Krawfish::Log;
use strict;
use warnings;

# TODO:
#   Rename to FieldCalc or FieldSum

# TODO:
#   Support corpus classes

use constant {
  DEBUG          => 1
};

sub new {
  my $class = shift;
  my $self = bless {
    fields_obj => shift,

    # This needs to be numerical field ids!
    field_ids =>  [map { ref($_) ? $_->term_id : $_ } @{shift()}],
  }, $class;

  # Initialize aggregator
  $self->{aggregation} = Krawfish::Posting::Aggregate::Values->new($self->{field_ids});

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
  my $aggr = $self->{aggregation};

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


sub collection {
  $_[0]->{collection};
};


# Stringification
sub to_string {
  return 'values:' . join(',', @{$_[0]->{field_ids}});
};


# Finish the aggregation
sub on_finish {
  my ($self, $collection) = @_;

  # Summarize collection
  $self->{aggregation}->summarize;

  # Maybe push to collection instead
  $collection->{values} = $self->{aggregation};
};


1;
