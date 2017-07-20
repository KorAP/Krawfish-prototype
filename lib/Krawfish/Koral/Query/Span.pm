package Krawfish::Koral::Query::Span;
use parent 'Krawfish::Koral::Query';
use Krawfish::Koral::Query::Term;
use Krawfish::Log;
use Krawfish::Query::Span;
use Scalar::Util qw/blessed/;
use strict;
use warnings;

# TODO: Rename 'wrap' to 'operand'

use constant DEBUG => 0;

sub new {
  my $class = shift;
  my $span = shift;

  # Span is a string
  unless (blessed $span) {
    return bless {
      operands => [Krawfish::Koral::Query::Term->new('<>' . $span)]
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

sub inflate {
  my ($self, $dict) = @_;

  print_log('kq_span', 'Inflate span') if DEBUG;

  $self->{operands}->[0] = $self->operand->inflate($dict);
  return $self;
};


# Todo: May be more complicated
sub optimize {
  my ($self, $index) = @_;
  return Krawfish::Query::Span->new(
    $index,
    $self->operand->to_term
  );
};



sub maybe_unsorted { 0 };

sub from_koral;
# Todo: Change the term_type!

sub to_string {
  return '<' . $_[0]->operand->to_string . '>';
};

1;
