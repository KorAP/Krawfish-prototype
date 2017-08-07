package Krawfish::Corpus::FieldID;
use parent 'Krawfish::Corpus';
use Krawfish::Posting::Doc;
use Krawfish::Query::Nothing;
use Krawfish::Log;
use strict;
use warnings;

use constant DEBUG => 0;

sub new {
  my ($class, $segment, $term_id) = @_;
  my $postings = $segment->postings($term_id)
    or return Krawfish::Query::Nothing->new;

  bless {
    segment => $segment,
    postings => $postings->pointer,
    term_id => $term_id
  }, $class;
};

sub clone {
  my $self = shift;
  return __PACKAGE__->new(
    $self->{segment},
    $self->{term_id}
  );
};

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


sub term_id {
  $_[0]->{term_id};
};


sub current {
  my $postings = $_[0]->{postings};
  return if $postings->pos == -1;
  return unless $postings->current;
  Krawfish::Posting::Doc->new(
    @{$postings->current}
  );
}

sub max_freq {
  $_[0]->{postings}->freq;
};

sub to_string {
  return '#' . $_[0]->term_id;
};

1;
