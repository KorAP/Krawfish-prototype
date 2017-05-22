package Krawfish::Query::Constraint::NotBetween;
use Krawfish::Query::Constraint::Position; # Export constants
use strict;
use warnings;

# Check, if a negative token is in between.
# Like [orth=Der][orth!=alte][orth=Mann].

# TODO:
#   Ensure, when this constraint is used,
#   that the constraint precedes(first,second) is true.

use constant ALL_MATCH => NEXTA | NEXTB | MATCH;

sub new {
  my $class = shift;
  bless {
    query => shift
  }, $class;
};


sub _init {
  my $self = shift;
  return if $self->{_init}++;
  $self->{query}->next;
};


sub check {
  my $self = shift;
  my ($payload, $first, $second) = @_;

  $self->_init;

  my $query = $self->{query};

  if ($query->current->doc_id < $first->doc_id) {
    $query->skip_doc($first->doc_id) or return 1;
  };

  # No negative between query match exists
  return ALL_MATCH unless $query->current;

  # Get negative inbetween
  my $negative;
  while ($negative = $query->current) {

    # The negative is in a different document
    if ($negative->doc_id != $first->doc_id) {
      return ALL_MATCH;
    };

    # [NEG]..[FIRST] | [NEG][FIRST] | [FIRST[NEG]..]
    if ($negativ->start < $first->end) {

      # Move negative query to at least the end of the next position
      $query->next_pos($first->end);
    }

    # [FIRST]...[NEG]
    elsif ($negative->start > $first->end) {
      return ALL_MATCH;
    }

    # [FIRST][NEG]...
    # [NEG[SECOND]..]
    elsif ($negative->end > $second->start) {
      return ALL_MATCH;
    }

    # [NEG]..[SECOND]
    elsif ($negative->end < $second->start) {
      $query->next;
    }

    # No match!
    else {
      return NEXTA | NEXTB;
    };
  };

  return ALL_MATCH;
};

1;
