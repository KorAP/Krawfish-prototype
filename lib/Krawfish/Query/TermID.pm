package Krawfish::Query::TermID;
use parent 'Krawfish::Query';
use Krawfish::Posting::Span;
use Krawfish::Query::Filter;
use Krawfish::Log;
use strict;
use warnings;

use constant DEBUG => 0;

# Constructor
sub new {
  my ($class, $segment, $term_id) = @_;

  # Get postings pointer
  my $postings = $segment->postings($term_id)
    or return Krawfish::Query::Nowhere->new;

  bless {
    segment => $segment,
    postings => $postings->pointer,
    term_id => $term_id
  }, $class;
};


# Clone query
sub clone {
  my $self = shift;
  __PACKAGE__->new(
    $self->{segment},
    $self->{term_id}
  );
};


# Move to next posting
sub next {
  my $self = shift;

  # TODO: This should respect filters
  my $return = $self->{postings}->next;
  if (DEBUG) {
    print_log('term_id', 'Next #' . $self->term_id . ' - current is ' .
                ($return ? $self->current : 'none'));
  };
  return $return;
};


# Get current posting
sub current {
  my $postings = $_[0]->{postings};
  return if $postings->pos == -1;
  return unless $postings->current;

  my $current = $postings->current;

  Krawfish::Posting::Span->new(
    doc_id  => $current->[0],
    start   => $current->[1],
    end     => $current->[2],
    payload => $current->[3]
  );
};


# This parameter is relevant, as it is requested
# e.g. from termFreq to count all frequencies
# per requested term
sub term_id {
  $_[0]->{term_id};
};


# Get maximum frequency
sub max_freq {
  $_[0]->{postings}->freq;
};


# Get the frequency of the term in
# the current document
sub freq_in_doc {
  $_[0]->{postings}->freq_in_doc;
};


# Stringification
sub to_string {
  '#' . $_[0]->term_id;
};


# Skip to target doc id
sub skip_doc {
  $_[0]->{postings}->skip_doc($_[1]);
};


# Complexity of the query
sub complex {
  0;
};


# Filter query by VC
sub filter_by {
  my ($self, $corpus) = @_;
  return Krawfish::Query::Filter->new(
    $self, $corpus->clone
  );
};


1;
