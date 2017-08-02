package Krawfish::Koral::Query::SpanID;
use parent 'Krawfish::Koral::Query::Span';
use Krawfish::Query::SpanID;
use warnings;
use strict;

# TODO:
#   This may be irrelevant if the postings in
#   Krawfish::Query::Span/SpanID could be
#   more general.

sub new {
  my ($class, $term_id) = @_;
  bless \$term_id, $class;
};

sub type {
  'spanid'
};


sub optimize {
  my ($self, $segment) = @_;
  return Krawfish::Query::SpanID->new($segment, $$self);
};

sub to_string {
  '#' . ${$_[0]};
};

1;
