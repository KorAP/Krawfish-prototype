package Krawfish::Query;
use Krawfish::Log;
use Scalar::Util qw/blessed/;
use strict;
use warnings;

use constant DEBUG => 0;

# Current span object
sub current {
  my $self = shift;
  return unless defined $self->{doc_id};
  return Krawfish::Posting->new(
    doc_id  => $self->{doc_id},
    start   => $self->{start},
    end     => $self->{end},
    payload => $self->{payload}
  );

  # TODO: May have an offset value as well
};


# Overwrite
# TODO: Accepts a target doc
# TODO: Returns the doc_id of the current posting
sub next;


# TODO:
# This is a value that should probably be stored
# at span-beginnings and can help to jump through very long
# sequences of spans
sub max_length;


# This is only relevant for term posting lists
sub next_doc {
  my $self = shift;
  my $current_doc_id = $self->current->doc_id;

  print_log('query', "Go to next doc following $current_doc_id") if DEBUG;

  do {
    $self->next or return;
  } until ($self->current->doc_id > $current_doc_id);

  return 1;
};


sub freq_in_doc {
  warn 'freq_in_doc only supported for term queries (see PostingPointer)';
};


# Skip to (or beyond) a certain document id
sub skip_doc {
  my ($self, $doc_id) = @_;

  print_log('query', 'Skip to doc id ' . $doc_id) if DEBUG;

  while (!$self->current || $self->current->doc_id < $doc_id) {
    $self->next_doc or return;
  };

  return $self->current->doc_id;
};


# Skip to (or beyond) a certain position
# Returns true, if the new current is positioned
# in the same document beyond the given pos.
# Otherwise returns false.
sub skip_pos {
  my ($self, $pos) = @_;
  my $current = $self->current or return;
  my $doc_id = $current->doc_id;

  while (($current = $self->current) && $current->doc_id == $doc_id) {

    if ($current->start < $pos) {
      print_log('query', "Skip " . $current->to_string .
                  " to pos $pos in doc id $doc_id") if DEBUG;
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
      print_log('filter', 'Forward second') if DEBUG;
      $second->skip_doc($first_c->doc_id) or return;
      $second_c = $second->current;
    };
  };

  return 1;
};

# In Lucene it's exemplified:
# int advance(int target) {
#   int doc;
#   while ((doc = nextDoc()) < target) {
#   }
#   return doc;
# }


# The maximum possible frequency of the query
sub max_freq {
  warn 'Not implemented for this query: ' . blessed $_[0];
};


# This will set a filter flag,
# so with filter_by() all flagged queries
# can be filtered
sub filter {
  0; # TODO: Make this an attribute
};


sub filter_by;

# Overwrite
sub to_string {
  ...
};


# Override in Krawfish::Collection
sub current_match {
  return undef;
};



1;
