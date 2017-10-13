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
#   Support corpus classes!

# TODO:
#   In case the field has no rank, because it is a multivalued field,
#   a different mechanism has to be used!

# TODO: It may be beneficial to store example documents in the
#   field ranks, too - so they don't need to be collected on the way ...
#   See Group::Fields as well.
#   For this, add a "witness" field

# TODO:
#   Field aggregates should be sortable either <asc> or <desc>,
#   and should have a count limitation, may be even a start_index and an items_per_page


sub new {
  my $class = shift;
  bless {
    field_obj  => shift,
    field_keys => [map { ref($_) ? $_->term_id : $_ } @{shift()}],

    # TODO:
    #   This needs to be an object, so it can be inflated again!
    # collection => {}, # The buckets in memory

    aggregation => Krawfish::Koral::Result::Aggregate::Fields->new,

    freq    => 0,
    field_freqs => {}
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
  my $aggr = $self->{aggregation};

  # Skip to document in question
  # TODO:
  #   skip_doc should ALWAYS return either the document or NOMOREDOC!

  if ($pointer->skip_doc($doc_id) == $doc_id) {

    $aggr->flush;

    # my $coll = $self->{collection};

    # Get all requested fields
    # my @fields;

    if (DEBUG) {
      print_log('aggr_fields', 'Look for frequencies for key ids ' .
                  join(', ', map { '#' . $_ } @{$self->{field_keys}}) . " in doc $doc_id");
    };

    # Iterate over all fields
    foreach my $field ($pointer->fields(@{$self->{field_keys}}))  {

      # This should probably be a method in the fields pointer!
      next if $field->type eq 'store';

      # Increment occurrence
      $aggr->incr_doc($field->key_id, $field->term_id);

      if (DEBUG) {
        print_log('aggr_fields', '#' . $field->term_id . ' has frequencies');
      };
    };
  }

  # Do not check rank
  else {
    $aggr->flush;
  };
};


# On every match
sub each_match {
  $_[0]->{aggregation}->incr_match;
};


# finish the results
sub on_finish {
  my ($self, $collection) = @_;

  $self->{aggregation}->flush;

  $collection->{fields} = $self->{aggregation};
};


sub collection {
  # Return fields
  # Example structure for year
  # {
  #   1997 => [4, 67],
  #   1998 => [5, 89],
  #   1999 => [3, 20]
  # }
  $_[0]->{collection};
};


sub to_string {
  return 'fields:' . join(',', map { '#' . $_ } @{$_[0]->{field_keys}});
};


1;
