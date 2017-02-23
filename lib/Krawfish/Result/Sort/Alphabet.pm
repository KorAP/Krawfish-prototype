package Krawfish::Result::Sort::Alphabet;
use Krawfish::Log;
use strict;
use warnings;

use constant DEBUG => 0;

# Sort result alphabetically.
# Requires a class or the match - and based on the start + end, the term_ids are requested
# and added per match as an array.
# Then the matches are sorted one term_id position after the other.
#
# In case the ordering is reverse alphabetically, the term_id array is reversed as well.
#
# In case the term_id array has no equal length, the shorter array is preferred.
#
# EXAMPLE:
#   match1: [term_1, term_2, term_3]
#   match2: [term_1, term_2, term_3]
#
# This is necessary for all alphabetical sortings!


# ---- old:
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
