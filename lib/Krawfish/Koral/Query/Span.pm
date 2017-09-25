package Krawfish::Koral::Query::Span;
use parent 'Krawfish::Koral::Query';
use Krawfish::Util::Constants ':PREFIX';
use Krawfish::Koral::Query::TermID;
use Krawfish::Koral::Query::Term;
use Krawfish::Log;
use Scalar::Util qw/blessed/;
use strict;
use warnings;

use constant DEBUG => 0;

sub new {
  my $class = shift;
  my $span = shift;

  # Span is a string
  unless (blessed $span) {
    return bless {
      operands => [Krawfish::Koral::Query::Term->new(SPAN_PREF . $span)]
    }, $class;
  };

  bless {
    operands => [$span]
  }, $class;
};


sub type { 'span' };


# There are no classes allowed in spans
sub remove_classes {
  $_[0];
};


sub to_koral_fragment {
  my $self = shift;
  my $span = {
    '@type' => 'koral:span'
  };
  if ($self->operand) {
    $span->{wrap} = $self->operand->to_koral_fragment
  };

  return $span;
};


# TODO: Some error handling
sub normalize {
  return $_[0];
};



sub identify {
  my ($self, $dict) = @_;

  # This is currently not supported
  unless ($self->is_regex) {

    my $term = $self->to_term;

    print_log('kq_span', "Translate span $term to term_id") if DEBUG;

    my $term_id = $dict->term_id_by_term(SPAN_PREF . $term);

    return $self->builder->nowhere unless defined $term_id;

    return Krawfish::Koral::Query::TermID->new($term_id);
  };

  warn 'Regexes are currently not supported';
};


# TODO:
#   Currently not supported
sub is_regex {
  0;
};


sub to_term {
  $_[0]->operand->to_string;
};


# Todo: May be more complicated
sub optimize {
  warn 'Span queries need to be identified before';
};


# A span may have length 0 in case it is an empty annotation
# like a page break
sub min_span {
  0;
};


# A termGroup always spans exactly one token
sub max_span {
  return 0 if $_[0]->is_null;
  -1;
};


sub maybe_unsorted { 0 };


sub from_koral {
  ...
};
# Todo: Change the term_type!


sub to_string {
  return '<' . $_[0]->operand->to_string . '>';
};

1;
