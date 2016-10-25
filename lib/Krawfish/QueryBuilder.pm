package Krawfish::QueryBuilder;
use Krawfish::Query::Token;
use Krawfish::Query::Span;
use Krawfish::Query::Next;
use strict;
use warnings;

sub new {
  my $class = shift;
  my $index = shift;
  bless {
    index => $index
  }, $class;
};

sub token {
  my $self = shift;
  my $term = shift;
  return Krawfish::Query::Token->new(
    $self->{index},
    $term
  );
};

sub span {
  my $self = shift;
  my $term = shift;
  return Krawfish::Query::Span->new(
    $self->{index},
    $term
  );
};


sub sequence {
  my $self = shift;
  my ($element1, $element2) = @_;
  return Krawfish::Query::Next->new(
    $element1, $element2
  );
};

sub sort_by {
  my $self = shift;
  my $field = shift;
  # This will walk through the term dictionary
  # Using the field prefix in order
  # And use the doc_ids to intersect with the matching list
  # For this, the Match may first be converted to
  # a bitstream of documents
  ...
};

1;
