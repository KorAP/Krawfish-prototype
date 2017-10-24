package Krawfish::Query;
use Krawfish::Log;
use Krawfish::Posting::Span;
use Scalar::Util qw/blessed refaddr/;
use strict;
use warnings;


# Krawfish::Query is the base class for all span queries.

# TODO:
#   Use a boolean init value to indicate a
#   query needs a next first

use constant DEBUG => 0;

# Current span object
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


# Move to next posting
# Overwrite
# Returns true if nexting works
sub next {
  ...
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


# Overwrite
# Skip to (or beyond) a certain doc id.
# This should be overwritten to more effective methods.
sub skip_doc {
  my ($self, $target_doc_id) = @_;

  print_log('query', refaddr($self) . ': skip to doc id ' . $target_doc_id) if DEBUG;

  while (!$self->current || $self->current->doc_id < $target_doc_id) {
    $self->next_doc or return;
  };

  # TODO:
  #   Return NOMORE in case no more
  #   documents exist
  return $self->current->doc_id;
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


# Move both spans to the same document
sub same_doc {
  my ($self, $second) = @_;

  my $first_c = $self->current or return;
  my $second_c = $second->current or return;

  # Iterate to the first matching document
  while ($first_c->doc_id != $second_c->doc_id) {
    print_log('query', 'Current span is not in docs') if DEBUG;

    # Forward the first span to advance to the document of the second span
    if ($first_c->doc_id < $second_c->doc_id) {
      print_log('query', 'Forward first') if DEBUG;
      $self->skip_doc($second_c->doc_id) or return;
      $first_c = $self->current;
    }

    # Forward the second span to advance to the document of the first span
    else {
      print_log('query', 'Forward second') if DEBUG;
      $second->skip_doc($first_c->doc_id) or return;
      $second_c = $second->current;
    };
  };

  return 1;
};


# Clone query
# (Not implemented yet)
sub clone {
  warn $_[0];
  ...
};


# Per default every operation is complex
sub complex {
  return 1;
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


# Get maximum possible frequency of the query
sub max_freq {
  warn 'Not implemented for this query: ' . blessed $_[0];
};


# Filter nothing
sub filter_by {
  warn 'Not implemented by default';
};


# Stringification
# Overwrite
sub to_string {
  ...
};


# Get current match
# Override
sub current_match {
  return undef;
};



# Lose all information about the query
sub close {

};


# Stop compilation of results in non-compile queries
# TODO:
#   Rename to compile()
sub collect {
  return 1;
};

1;
