package Krawfish::Compile::Segment::Aggregate::Values;
use Krawfish::Koral::Result::Aggregate::Values;
use Krawfish::Log;
use strict;
use warnings;
use Role::Tiny::With;

with 'Krawfish::Compile::Segment::Aggregate::Base';

# TODO:
#   Rename to FieldCalc or FieldSum

# TODO:
#   This is rather a group query or better:
#   An aggregation on groups!

# TODO:
#   Support flags on construction

# TODO:
#   This may be reused for aggregation on groups!
#   That means, it requires pattern passing as well.

use constant DEBUG => 0;

sub new {
  my $class = shift;
  my $self = bless {
    fields_obj => shift,

    # This needs to be numerical field ids!
    field_ids =>  [map { ref($_) ? $_->term_id : $_ } @{shift()}],
    flags => shift
  }, $class;

  if (DEBUG) {
    print_log(
      'aggr_values',
      'Initialize field value aggregation on ' .
        join(',', @{$self->{field_ids}})
      );
  };

  # Initialize aggregator
  $self->{result} = Krawfish::Koral::Result::Aggregate::Values->new(
    $self->{field_ids},
    $self->{flags}
  );

  return $self;
};


# Clone query
sub clone {
  my $self = shift;
  __PACKAGE__->new(
    $self->{fields_obj},
    [@{$self->{field_ids}}],
    $self->{flags}
  );
};


# Initialize field pointer
sub _init {
  return if $_[0]->{field_pointer};

  my $self = shift;

  $self->{field_pointer} = $self->{fields_obj}->pointer;
};


# Release for each doc
sub each_doc {
  my ($self, $current) = @_;

  $self->_init;

  # Get current document
  my $doc_id = $current->doc_id;

  if (DEBUG) {
    print_log(
      'aggr_values',
      "Aggregate on field values for doc_id $doc_id"
    );
  };

  my $pointer = $self->{field_pointer};

  # Get aggregation information
  my $aggr = $self->result;

  # Get flags from the document
  my $flags = $current->flags($self->{flags});

  # Move fields pointer to current document
  if ($pointer->skip_doc($doc_id) == $doc_id) {

    # collect values
    my @values = $pointer->int_fields(@{$self->{field_ids}})
      or return;

    # Aggregate all values
    foreach my $field (@values) {

      # Aggregate value
      $aggr->incr_doc($field->key_id, $field->value, $flags);
    };
  };
};


# Stringification
sub to_string {
  return 'values:' . join(',', map { '#' . $_ } @{$_[0]->{field_ids}});
};


1;
