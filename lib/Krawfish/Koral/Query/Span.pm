package Krawfish::Koral::Query::Span;
use parent 'Krawfish::Koral::Query';
use Krawfish::Koral::Query::Term;
use Krawfish::Log;
use Krawfish::Query::Span;
use Scalar::Util qw/blessed/;
use strict;
use warnings;

# TODO: Rename 'wrap' to 'operand'

use constant DEBUG => 1;

sub new {
  my $class = shift;
  my $span = shift;

  # Span is a string
  unless (blessed $span) {
    return bless {
      wrap => Krawfish::Koral::Query::Term->new('<>' . $span),
    }, $class;
  };

  bless {
    wrap => $span
  }, $class;
};

sub type { 'span' };

sub wrap {
  shift->{wrap};
};

# Remove classes passed as an array references
sub remove_classes {
  $_[0];
};

sub to_koral_fragment {
  my $self = shift;
  my $span = {
    '@type' => 'koral:span'
  };
  if ($self->wrap) {
    $span->{wrap} = $self->wrap->to_koral_fragment
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

  $self->{wrap} = $self->wrap->inflate($dict);
  return $self;
};

# Todo: May be more complicated
sub optimize {
  my ($self, $index) = @_;
  return Krawfish::Query::Span->new(
    $index,
    $self->wrap->to_term
  );
};


sub plan_for {

  warn 'DEPRECATED';
  my $self = shift;
  my $index = shift;
  # Todo: May be more complicated
  return Krawfish::Query::Span->new(
    $index,
    $self->wrap->to_term
  );
};

# Filter by corpus
sub filter_by {
  ...
};


sub maybe_unsorted { 0 };

sub from_koral;
# Todo: Change the term_type!

sub to_string {
  return '<' . $_[0]->wrap->to_string . '>';
};

1;
