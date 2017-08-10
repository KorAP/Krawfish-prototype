package Krawfish::Index::Forward;
use Krawfish::Index::Forward::Pointer;
use Krawfish::Index::Forward::Stream;
use Krawfish::Index::Forward::Doc;
use Krawfish::Log;
# use Krawfish::Index::Store::V1::ForwardIndex;
use warnings;
use strict;

use constant DEBUG => 1;

# TODO:
#   This API needs to be backed up by a store version.

sub new {
  my $class = shift;

  bless {
    docs => [],
    last_doc_id => -1
  }, $class;
};


# Get last document identifier aka max_doc_id
sub last_doc_id {
  $_[0]->{last_doc_id};
};


# Accept a Krawfish::Koral::Document object
sub add {
  my ($self, $doc) = @_;
  my $doc_id = $self->{last_doc_id}++;

  # TODO:
  #   use Krawfish::Index::Store::V1::ForwardIndex->new;
  $self->{docs}->[$self->last_doc_id] =
    Krawfish::Index::Forward::Doc->new($doc);

  return $doc_id;
};


# Get doc from list (as long as the list provides random access to docs
sub doc {
  my ($self, $doc_id) = @_;
  print_log('fwd', 'Get document for id ' . $doc_id) if DEBUG;
  return $self->{docs}->[$doc_id];
};

# Get a specific forward indexed document by doc_id
sub pointer {
  my $self = shift;
  return Krawfish::Index::Forward::Pointer->new($self);
};


1;
