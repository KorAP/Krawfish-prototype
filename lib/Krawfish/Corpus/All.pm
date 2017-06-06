package Krawfish::Corpus::All;
use Krawfish::Index::PostingsLive;
use Krawfish::Posting::Doc;
use Krawfish::Query::Nothing;
use Krawfish::Log;
use strict;
use warnings;

use constant DEBUG => 0;

# TODO:
#   Rename to "Any"

sub new {
  my ($class,$index) = @_;

  # Get live pointer
  my $live = $index->live->pointer;

  # Index is empty
  return Krawfish::Query::Nothing->new
    if $live->freq == 0;

  bless {
    live => $live
  }, $class;
};

sub next {
  my $self = shift;

  print_log('cq_any', 'Next live doc') if DEBUG;

  return $self->{live}->next;
};

sub freq {
  $_[0]->{live}->freq;
};


# TODO:
# This currently does not support flags
sub current {
  my $live = $_[0]->{live};

  return if $live->doc_id == -1 || (
    $live->doc_id > $live->last_doc
  );

  print_log('cq_any', 'Current doc_id is ' . $live->current) if DEBUG;

  Krawfish::Posting::Doc->new(
    $live->current
  );
};


sub skip_doc {
  my $self = shift;
  return $self->{live}->skip_doc(@_);
};

sub to_string {
  '[1]';
};

1;
