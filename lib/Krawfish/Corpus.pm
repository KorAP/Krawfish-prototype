package Krawfish::Corpus;
use parent 'Krawfish::Query';
use strict;
use warnings;

# Krawfish::Corpus is the base class for all corpus queries.

# Current span object
sub current {
  my $self = shift;
  return unless defined $self->{doc_id};
  return Krawfish::Posting->new(
    doc_id => $self->{doc_id},
    flags  => $self->{flags}
  );
};


# Overwrite query object
sub next_doc {
  return $_[0]->next;
};


1;
