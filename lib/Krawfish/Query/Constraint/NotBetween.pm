package Krawfish::Query::Constraint::NotBetween;
use Krawfish::Log;
use strict;
use warnings;

# Check, if a negative token is in between.
# Like [orth=Der][orth!=alte][orth=Mann].

# TODO:
#   Ensure, when this constraint is used,
#   that the constraint precedes(first,second) is true.



use constant {
  NEXTA => 1,
  NEXTB => 2,
  MATCH => 4,
  ALL_MATCH => (1 | 2 | 4),
  DEBUG => 1
};

sub new {
  my $class = shift;
  bless {
    query => shift,
    buffer => Krawfish::Util::Buffer->new
  }, $class;
};


sub init {
  my $self = shift;
  return if $self->{init}++;
  print_log('notC', 'Init notBetween query') if DEBUG;
  $self->{query}->next;
  return;
};


sub check {
  my $self = shift;
  my ($first, $second, $payload) = @_;

  $self->init;

  # TODO:
  #   Use buffer API here

  my $query = $self->{query};

  if (DEBUG) {
    print_log('notC',
              'Configuration is '
                . $first->to_string . ',' . $second->to_string
                . ' with negative at ' . $query->current->to_string
              )
  };


  if ($query->current->doc_id < $first->doc_id) {
    if (DEBUG) {
      print_log('notC', 'Current negative doc id is less than first doc id');
    };

    # There is no match anymore
    $query->skip_doc($first->doc_id) or return ALL_MATCH;
  };

  # No negative between query match exists
  return ALL_MATCH unless $query->current;

  # Get negative inbetween
  my $negative;
  while ($negative = $query->current) {

    print_log('notC', 'Check position of current negative') if DEBUG;

    # The negative is in a different document
    if ($negative->doc_id != $first->doc_id) {

      print_log('notC', 'Document does not match') if DEBUG;
      return ALL_MATCH;
    };

    # [NEG]..[FIRST] | [NEG][FIRST] | [FIRST[NEG]..]
    if ($negative->start < $first->start) {
      print_log('notC', 'Current negative starts before first starts') if DEBUG;

      # Move negative query to at least the end of the next position
      $query->skip_pos($first->start);
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

sub to_string {
  my $self = shift;
  'notBetween=' . $self->{query}->to_string;
};



1;
