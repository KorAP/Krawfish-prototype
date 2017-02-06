package Krawfish::Koral::Query::Length;
use parent 'Krawfish::Koral::Query';
use Scalar::Util qw/looks_like_number/;
use Krawfish::Query::Nothing;
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
    unless (looks_like_number($_[1])) {
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


sub plan_for {
  my $self = shift;
  my $index = shift;

  return Krawfish::Query::Nothing->new if $self->is_null;

  my $span = $self->{span}->plan_for($index);

  # No boundaries given
  if (!$self->{min} && !$self->{max}) {
    return $span;
  };

  # Todo: May be more complicated for things like 1..undef
  return Krawfish::Query::Length->new(
    $span,
    $self->{min},
    $self->{max},
    $self->{token}
  );
};


# Filter by corpus
sub filter_by {
  my $self = shift;
  my $corpus_query = shift;
  $self->{span}->filter_by($corpus_query);
  return $self;
};


sub maybe_unsorted {
  $_[0]->{span}->maybe_unsorted;
};

sub from_koral;
# Todo: Change the term_type!

sub to_string {
  my $self = shift;
  my $str = 'length(';
  $str .= $self->{min} // '0';
  $str .= '-';
  $str .= $self->{max} // 'inf';
  $str .= ';' . $self->{token} if $self->{token};
  $str .= ':';
  $str .= $self->{span}->to_string;
  return $str . ')';
};

sub is_any { $_[0]->{span}->is_any };
sub is_optional { $_[0]->{span}->is_optional };
sub is_null { $_[0]->{span}->is_null };
sub is_negative { $_[0]->{span}->is_negative };
sub is_extended_right { $_[0]->{span}->is_extended_right };
sub is_extended_left { $_[0]->{span}->is_extended_left };
sub freq { $_[0]->{span}->freq; };

1;
