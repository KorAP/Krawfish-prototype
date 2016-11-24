package Krawfish::Koral::Query::Span;
use parent 'Krawfish::Koral::Query';
use Krawfish::Koral::Query::Term;
use Krawfish::Query::Span;
use Scalar::Util qw/blessed/;
use strict;
use warnings;

# Todo: Support frequency here!

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

sub plan_for {
  my $self = shift;
  my $index = shift;
  # Todo: May be more complicated
  return Krawfish::Query::Span->new(
    $index,
    $self->wrap->term
  );
};

sub maybe_unsorted { 0 };

sub from_koral;
# Todo: Change the term_type!

sub to_string {
  return '<' . $_[0]->wrap->to_string . '>';
};

1;
