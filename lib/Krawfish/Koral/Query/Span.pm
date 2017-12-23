package Krawfish::Koral::Query::Span;
use Role::Tiny::With;
use Krawfish::Util::Constants ':PREFIX';
use Krawfish::Koral::Query::Term;
use Krawfish::Log;
use Scalar::Util qw/blessed/;
use strict;
use warnings;

with 'Krawfish::Koral::Query';

use constant DEBUG => 0;

sub new {
  my ($class, $span) = @_;

  unless ($span) {
  }

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

    return Krawfish::Koral::Query::Term->new($term_id);
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


# Todo: Change the term_type!
sub from_koral {
  my ($class, $kq) = @_;
  my $qb = $class->builder;

  # No wrap
  unless ($kq->{'wrap'}) {

    # TODO:
    #   This should return an error!
    warn 'Wrap not supported!'
  }

  # Wrap is a term
  else {
    my $wrap = $kq->{wrap};
    if ($wrap->{'@type'} eq 'koral:term') {
      return $class->new($qb->from_koral_term($wrap)->term_type('span'));
    }
    else {
      warn 'Wrap type not supported!'
    };
  }
};


sub to_string {
  my ($self, $id) = @_;
  return '<' . $self->operand->to_string($id) . '>';
};

1;
