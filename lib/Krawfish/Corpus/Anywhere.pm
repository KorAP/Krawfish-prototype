package Krawfish::Corpus::Anywhere;
use strict;
use warnings;
use Role::Tiny;
use Krawfish::Index::PostingsLive;
use Krawfish::Posting;
use Krawfish::Query::Nowhere;
use Scalar::Util qw/refaddr/;
use Krawfish::Log;

with 'Krawfish::Corpus';

use constant DEBUG => 0;


# Construct query on live documents
sub new {
  my ($class, $segment) = @_;

  # Get live pointer
  my $live = $segment->live->pointer;

  # Index is empty
  return Krawfish::Query::Nowhere->new
    if $live->freq == 0;

  bless {
    segment => $segment,
    live => $live
  }, $class;
};


# Clone query
sub clone {
  __PACKAGE__->new(
    $_[0]->{segment}
  );
};


# Move to next
sub next {
  my $self = shift;
  print_log('vc_any', refaddr($self) . ': Next live doc') if DEBUG;
  return $self->{live}->next;
};


# Get number of live documents
sub max_freq {
  $_[0]->{live}->freq;
};


# TODO:
# This currently does not support flags
sub current {
  my $live = $_[0]->{live};

  return if $live->doc_id == -1 || (
    $live->doc_id >= $live->next_doc_id
  );

  print_log('vc_any', 'Current doc_id is ' . $live->current) if DEBUG;

  Krawfish::Posting->new(
    doc_id => $live->current
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
