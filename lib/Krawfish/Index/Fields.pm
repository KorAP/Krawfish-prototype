package Krawfish::Index::Fields;
use Krawfish::Index::FieldsRank;
use Krawfish::Log;
use strict;
use warnings;

use constant DEBUG => 0;

sub new {
  my $class = shift;
  bless {
    file => shift,
    array => [], # doc array
    ranks => {}, # ranked lists
    identifier => shift
  }, $class;
};

sub store {
  my $self = shift;
  my $doc_id = shift;
  my ($key, $value) = @_;

  # Preset fields with doc_id
  my $fields = ($self->{array}->[$doc_id] //= {});

  # Delete cached ranks
  delete $self->{ranks}->{$key};

  print_log(
    'fields',
    'Store field ' . $key . ':' . $value . ' for ' . $doc_id
  ) if DEBUG;

  # TODO:
  #   This needs to have information whether it's a string
  #   or an integer (mainly for sorting)
  $fields->{$key} = $value;
};


# Get the field value of a document
sub get {
  my $self = shift;
  my $doc_id = shift;
  my $doc = $self->{array}->[$doc_id];

  # Get specific field
  if (@_) {
    print_log(
      'fields',
      'Get field ' . $_[0] . ' for ' . $doc_id
    ) if DEBUG;

    return $doc->{$_[0]} ;
  };

  # Get all fields
  return $doc;
};


# Return documents by array
sub docs {
  return $_[0]->{array};
};


# Sort documents by a field and attach a numerical rank.
# Returns the maximum rank and a vector of ranks at doc id position.
# Ranks can be set multiple timnes
#
# TODO:
#   These ranks may also be used for facet search, because
#   remembering the ranks and increment their values will
#   return the most common k facets of the field quickly.
#   Returning the fields per rank, however, may become
#   a linear search for the first rank in the ranked fields,
#   which may be slow.
#   But nonetheless, the max_rank field may also give a hint,
#   if the field is good for faceting! (unique ranks per field
#   are bad, for example!)
#
# TODO:
#   Return object
#
sub ranked_by {
  my ($self, $field) = @_;

  print_log(
    'fields',
    'Get rank vector for ' . $field
  ) if DEBUG;

  # TODO:
  #   Currently ranks are set absolutely - but they should be set
  #   multiple times to make sorts for multiple fields
  #
  # TODO: Check if the field needs to be sorted
  #   numerically or based on a collation

  my $ranks = $self->{ranks};

  # Lookup at disk
  return $ranks->{$field} if $ranks->{$field};

  # Add rank
  $ranks->{$field} = Krawfish::Index::FieldsRank->new(
    [grep { defined $_ } map { $_->{$field} } @{$self->{array}}]
  );

  if (DEBUG) {
    print_log(
      'fields',
      'Return rank vector for ' . $field
    );
  };

  # Return ranked list
  return $ranks->{$field};
};


1;
