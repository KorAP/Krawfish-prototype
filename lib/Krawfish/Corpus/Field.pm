package Krawfish::Corpus::Field;
use parent 'Krawfish::Corpus';
use Krawfish::Index::PostingsList;
use Krawfish::Posting::Doc;
use Krawfish::Query::Nothing;
use Krawfish::Log;
use strict;
use warnings;

use constant DEBUG => 0;

sub new {
  my ($class, $index, $term) = @_;
  my $postings = $index->dict->pointer('+' . $term)
    or return Krawfish::Query::Nothing->new;

  bless {
    postings => $postings,
    term => $term
  }, $class;
};

sub next {
  my $self = shift;

  print_log('field', 'Next "'.$self->term.'"') if DEBUG;

  my $return = $self->{postings}->next;
  if (DEBUG) {
    print_log('field', ' - current is ' . $self->current->to_string) if $return;
    print_log('field', ' - no current');
  };
  return $return;
};


sub term {
  $_[0]->{term};
};


sub current {
  my $postings = $_[0]->{postings};
  return if $postings->pos == -1;
  return unless $postings->current;
  Krawfish::Posting::Doc->new(
    @{$postings->current}
  );
}

sub freq {
  $_[0]->{postings}->freq;
};

sub to_string {
  return "'" . $_[0]->term . "'";
};

1;
