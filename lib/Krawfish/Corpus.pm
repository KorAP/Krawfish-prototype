package Krawfish::Corpus;
use parent 'Krawfish::Query';
use strict;
use warnings;

# Current span object
sub current {
  my $self = shift;
  return unless defined $self->{doc_id};
  return Krawfish::Posting::Doc->new(
    $self->{doc_id}
  );
};


1;
