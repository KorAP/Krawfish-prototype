package Krawfish::Query;
use strict;
use warnings;
use Role::Tiny;
use Krawfish::Log;
use Krawfish::Posting::Span;
use Scalar::Util qw/blessed refaddr/;

with 'Krawfish::Corpus';
requires qw/skip_pos
            filter_by
            requires_filter/;


# Krawfish::Query is the base class for all span queries.

# TODO:
#   Use a boolean init value to indicate a
#   query needs a next first

use constant DEBUG => 0;

# Current span posting object
sub current {
  my $self = shift;
  return unless defined $self->{doc_id};
  return Krawfish::Posting::Span->new(
    doc_id  => $self->{doc_id},
    start   => $self->{start},
    end     => $self->{end},
    payload => $self->{payload},
    flags   => $self->{flags}
  );

  # TODO: May have an offset value as well
};


# This is only relevant for term posting lists
sub next_doc {
  my $self = shift;

  # TODO:
  #   There may be the need to
  #   have an _init value

  my $current = $self->current or return;
  my $current_doc_id = $current->doc_id;

  if (DEBUG) {
    print_log('query', refaddr($self) . ": go to next doc following $current_doc_id");
  };

  do {
    $self->next or return;
  } until ($self->current->doc_id > $current_doc_id);

  return 1;
};


# Skip to (or beyond) a certain position in the doc.
# Returns true, if the new current is positioned
# in the same document beyond the given pos.
# Otherwise returns false.
# TODO:
#   This behaviour should be improved!
sub skip_pos {
  my ($self, $target_pos) = @_;
  my $current = $self->current or return;
  my $doc_id = $current->doc_id;

  while (($current = $self->current) && $current->doc_id == $doc_id) {

    if ($current->start < $target_pos) {
      print_log('query', "Skip " . $current->to_string .
                  " to pos $target_pos in doc id $doc_id") if DEBUG;
      $self->next;
    }
    else {
      return 1;
    };
  };
  return;
};


# TODO:
#   This is a value that should probably be stored
#   at span-beginnings and can help to jump through very long
#   sequences of spans
sub max_length {
  ...
};


sub freq_in_doc {
  warn 'freq_in_doc only supported for term queries (see PostingPointer)';
};


# Get current match
sub current_match {
  return undef;
};



# Lose all information about the query
sub close {
  # Not yet implemented
};


1;
