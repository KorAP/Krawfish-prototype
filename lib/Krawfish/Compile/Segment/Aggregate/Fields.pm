package Krawfish::Compile::Segment::Aggregate::Fields;
use parent 'Krawfish::Compile::Segment::Aggregate::Base';
use Krawfish::Koral::Result::Aggregate::Fields;
use Krawfish::Util::String qw/squote/;
use Krawfish::Log;
use strict;
use warnings;

use constant DEBUG => 0;

# TODO:
#   In case the field has ranges, this will increment the aggregation
#   values for the whole range.

# TODO:
#   Simplify the counting by mapping the requested fields to
#   an array, that points to a map.

# TODO:
#   Look for fast int => int hash maps
#   http://java-performance.info/implementing-world-fastest-java-int-to-int-hash-map/
#   http://eternallyconfuzzled.com/tuts/algorithms/jsw_tut_hashing.aspx
#   https://gist.github.com/badboy/6267743

# TODO:
#   Field aggregates should be sortable either <asc> or <desc>,
#   and should have a count limitation, may be even a start_index and an items_per_page


# Constructor
sub new {
  my $class = shift;
  my ($field_obj, $keys) = @_;
  bless {
    field_obj  => $field_obj,
    field_keys => [map { ref($_) ? $_->term_id : $_ } @{$keys}],
    result     => Krawfish::Koral::Result::Aggregate::Fields->new,
    freq       => 0
  }, $class;
};


# Initialize field pointer
sub _init {
  return if $_[0]->{field_pointer};

  my $self = shift;

  print_log('aggr_fields', 'Create pointer on fields') if DEBUG;

  # Load the ranked list - may be too large for memory!
  $self->{field_pointer} = $self->{field_obj}->pointer;
};


# On every doc
sub each_doc {
  my ($self, $current) = @_;

  $self->_init;

  print_log('aggr_fields', 'Aggregate on fields') if DEBUG;

  my $doc_id = $current->doc_id;

  my $pointer = $self->{field_pointer};

  # Set match frequencies to all remembered doc frequencies
  my $result = $self->{result};

  # Skip to document in question
  # TODO:
  #   skip_doc should ALWAYS return either the document or NOMOREDOC!
  if ($pointer->skip_doc($doc_id) == $doc_id) {

    # Flush result
    $result->flush;

    if (DEBUG) {
      print_log('aggr_fields', 'Look for frequencies for key ids ' .
                  join(', ', map { '#' . $_ } @{$self->{field_keys}}) . " in doc $doc_id");
    };

    # Mix set flags with flags to aggregate on
    my $flags = $current->flags($self->{flags});

    # Iterate over all fields
    foreach my $field ($pointer->fields(@{$self->{field_keys}}))  {

      # This should probably be a method in the fields pointer!
      next if $field->type eq 'store';

      # Increment occurrence
      $result->incr_doc($field->key_id, $field->term_id, $flags);

      if (DEBUG) {
        print_log('aggr_fields', '#' . $field->term_id . ' has frequencies');
      };
    };
  }

  # Do not check rank
  else {
    $result->flush;
  };
};


# On every match
sub each_match {
  $_[0]->{result}->incr_match;
};


# Return result
#sub result {
  # Return fields
  # Example structure for year
  # {
  #   1997 => [4, 67],
  #   1998 => [5, 89],
  #   1999 => [3, 20]
  # }
#  $_[0]->{result};
#};


# Stringification
sub to_string {
  return 'fields:' . join(',', map { '#' . $_ } @{$_[0]->{field_keys}});
};


1;
