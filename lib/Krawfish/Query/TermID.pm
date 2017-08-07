package Krawfish::Query::TermID;
use parent 'Krawfish::Query';
use Krawfish::Posting::Token;
use Krawfish::Query::Filter;
use Krawfish::Log;
use strict;
use warnings;


use constant DEBUG => 1;

# Constructor
sub new {
  my ($class, $segment, $term_id) = @_;

  # Get postings pointer
  my $postings = $segment->postings($term_id)
    or return Krawfish::Query::Nothing->new;

  bless {
    postings => $postings->pointer,
    term_id => $term_id
  }, $class;
};


# Skip to next position
# This will initialize the posting list
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


# Return current object
sub current {
  my $postings = $_[0]->{postings};
  return if $postings->pos == -1;
  return unless $postings->current;

  Krawfish::Posting::Token->new(
    @{$postings->current}
  );
};

# This parameter is relevant, as it is requested e.g. from termFreq
# to count all frequencies per requested term
sub term_id {
  $_[0]->{term_id};
};


sub max_freq {
  $_[0]->{postings}->freq;
};

sub freq_in_doc {
  $_[0]->{postings}->freq_in_doc;
};

sub to_string {
  '#' . $_[0]->term_id;
};

sub skip_doc {
  $_[0]->{postings}->skip_doc($_[1]);
};


# Filter this query by a corpus
sub filter_by {
  my ($self, $corpus) = @_;
  return Krawfish::Query::Filter->new(
    $self, $corpus->clone
  );
};

1;
