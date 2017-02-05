package Krawfish::Koral::Query::Length;
use parent 'Krawfish::Koral::Query';
use Scalar::Util qw/looks_like_number/;
use Krawfish::Query::Length;
use strict;
use warnings;

sub new {
  my $class = shift;
  my $span = shift;

  # Expect parameters min-length, max-length
  # and tokenization that is the base for length
  my ($min, $max, $token);

  # All parameters set
  if (@_ == 3) {
    ($min, $max, $token) = @_;
  }

  # Two parameters
  elsif (@_ == 2) {
    if (looks_like_number($_[1])) {
      $min = $max = $_[0];
      $token = $_[1];
    }

    else {
      ($min, $max) = @_;
    };
  }

  # One parameter
  elsif (@_ == 1) {
    ($min, $max) = $_[0];
  };

  bless {
    span => $span,
    min => $min,
    max => $max,
    token => $token
  }, $class;
};

sub min {
  if (defined $_[1]) {
    $_[0]->{min} = $_[1];
    return $_[0];
  };
  $_[0]->{min};
};


sub max {
  if (defined $_[1]) {
    $_[0]->{max} = $_[1];
    return $_[0];
  };
  $_[0]->{max};
};

sub token_base {
  if (defined $_[1]) {
    $_[0]->{token} = $_[1];
    return $_[0];
  };
  $_[0]->{token};
};


sub type { 'length' };

sub span {
  shift->{span};
};


sub to_koral_fragment {
  ...
};



# TODO


sub plan_for {
  my $self = shift;
  my $index = shift;
  # Todo: May be more complicated for things like 1..undef
  return Krawfish::Query::Span->new(
    $index,
    $self->wrap->term
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
