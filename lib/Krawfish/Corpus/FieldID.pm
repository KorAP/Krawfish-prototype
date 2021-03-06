package Krawfish::Corpus::FieldID;
use strict;
use warnings;
use Role::Tiny::With;
use Krawfish::Posting;
use Krawfish::Query::Nowhere;
use Krawfish::Log;

with 'Krawfish::Corpus';

use constant DEBUG => 0;

sub new {
  my ($class, $segment, $term_id) = @_;
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
  return __PACKAGE__->new(
    $self->{segment},
    $self->{term_id}
  );
};


# Move to next posting
sub next {
  my $self = shift;

  print_log('field_id', 'Next "'.$self->term.'"') if DEBUG;

  my $return = $self->{postings}->next;
  if (DEBUG) {
    print_log('field_id', ' - current is ' . $self->current->to_string) if $return;
    print_log('field_id', ' - no current');
  };
  return $return;
};


# Get term identifier
sub term_id {
  $_[0]->{term_id};
};


# Get current posting
sub current {
  my $postings = $_[0]->{postings};
  return if $postings->pos == -1;

  return unless $postings->current;

  my $current = $postings->current;

  Krawfish::Posting->new(
    doc_id => $current->doc_id
  );
}


# Get maximum frequency
sub max_freq {
  $_[0]->{postings}->freq;
};


# stringification
sub to_string {
  return '#' . $_[0]->term_id;
};

1;
