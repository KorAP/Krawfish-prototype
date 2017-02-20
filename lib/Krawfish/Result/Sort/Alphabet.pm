package Krawfish::Result::Sort;
use Krawfish::Log;
use strict;
use warnings;

use constant DEBUG => 0;

# Sort by characters of a certain segment (either the first or the last).
# This will require to open the offset file to get the first two characters
# for bucket sorting per token and then request the
# forward index (the offset is already liftet and may be stored in the buckets
# as well) for fine grained sorting!

# TODO:
#   This will need to pass sorting criteria as strings for cluster sorting.
#   At least for the top k matches.

sub new {
  my $class = shift;
  my $self = bless {
    query => shift,
    index => shift,
    # top_k => shift
  }, $class;

  my $dict = $self->dict;
  my $subt = $self->subtokens;

  while ($query->next) {
    my $element = $query->current->clone;

    # Get the subtoken info
    my $x = $subt->get($element->doc_id, $element->start);

    # Add element with id for sorting
    push @record, [$element, $x->[2]]
  };

};
