package Krawfish::Koral::Query::Length;
use Role::Tiny::With;
use Scalar::Util qw/looks_like_number/;
use List::Util;
use Krawfish::Query::Length;
use strict;
use warnings;
use Memoize;
memoize('min_span');
memoize('max_span');

with 'Krawfish::Koral::Query::Proxy';
with 'Krawfish::Koral::Query';
with 'Krawfish::Koral::Query::Boundary';


# TODO:
#   Normalize chained length queries
#   length(0-3,length(1-3,query))

# TODO:
#   Check for query invalidity based on min_span and max_span
#   length(2-4, [Baum]) - although, this only works with token support!

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
    ($min, $max) = ($_[0], $_[0]);
  };

  if ($token) {
    warn 'Token definitions not yet supported!';
  };

  bless {
    operands => [$span],
    min => $min,
    max => $max,
    token => $token
  }, $class;
};


# Minimum span of the query in tokens
sub min_span {
  my $self = shift;

  # As per tokens are not supported,
  # min( refers to the minimum number of subtokens
  # As min_span refers to tokens and one token has, as minumum,
  # one subtoken, both values can't be compared. That's why
  # min_span of the operand is returned, as long as it is not 0.

  my $min_span = $self->operand->min_span;
  $min_span = $min_span == 0 ? ($self->min >= 1 ? 1 : 0) : $min_span;

  my $max_span = $self->max_span;

  return ($max_span != -1 && $max_span < $min_span) ? $max_span : $min_span;
};



# Maximum span of the query
sub max_span {
  my $self = shift;

  # As max_span refers to tokens and max refers
  # (as long tokens are not supported) subtokens,
  # those values are not interchangeable.
  # But one token spans at least one subtoken, so
  # if the subtoken boundary is smaller as max_span,
  # this is the new max_span.

  my $max_span = $self->operand->max_span;

  if ($max_span == -1) {
    return -1;
  }

  elsif ($self->max < $max_span) {
    return $self->max;
  };

  return $max_span;
};


sub token_base {
  if (defined $_[1]) {
    $_[0]->{token} = $_[1];
    return $_[0];
  };
  $_[0]->{token};
};


sub type { 'length' };


# Normalize query
sub normalize {
  my $self = shift;

  # Length is null
  if ($self->{max} == 0) {
    return $self->builder->null;
  };

  my $span;
  unless ($span = $self->operand->normalize) {
    $self->copy_info_from($self->operand);
    return;
  };

  # Span is null or nowhere
  if ($span->is_null) {
    return $self->builder->null;
  };

  if ($span->is_nowhere) {
    return $self->builder->nowhere;
  };

  # Matches anywhere
  #  if ($span->is_anywhere) {

  # TODO: Check for repetition!!!
    # if ($self->type)
    #
    #return $self->builder->repeat(
    #  $self->builder->anywhere,
    #  $self->min,
    #  $self->max
    #)->normalize;

  #  };

  # No boundaries given
  if (!defined $self->{min} && !defined $self->{max}) {
    return $span;
  };

  # Check the length for plausibility
  my $min = $self->min_span; # Is tokens, may span more subtokens
  my $max = $self->max;

  if ($min < $self->min) {
    $min = $self->min;
  };

  # The length is not plausible
  if (defined $min && defined $max && ($min > $max)) {

    # Cannot match
    return $self->builder->nowhere;
  };

  $self->operands([$span]);

  return $self;
};


# Optimize query
sub optimize {
  my ($self, $segment) = @_;

  # TODO: Add constraint instead of query, if implemented

  my $span = $self->operand->optimize($segment);

  # Nowhere set
  if ($span->max_freq == 0) {
    return Krawfish::Query::Nowhere->new;
  };

  return Krawfish::Query::Length->new(
    $span,
    $self->{min},
    $self->{max},
    $self->{token}
  );
};


# Serialize to koral fragment
sub to_koral_fragment {
  my $self = shift;
  return {
    '@type' => 'koral:group',
    operation => 'operation:length',
    boundary => $self->to_koral_boundary,
    # token    => $self->token_base,
    operands => [
      $self->operand->to_koral_fragment
    ]
  };
};


# Deserialize from koral fragment
sub from_koral {
  my ($class, $kq) = @_;

  my $qb = $class->builder;

  my @param = ();
  my ($min, $max) = $class->from_koral_boundary($kq->{boundary});
  push @param, $min if defined $min;
  push @param, $max if defined $max;

  # TODO:
  #   Not yet implemented
  push @param, $kq->{token} if $kq->{token};

  return $class->new(
    $qb->from_koral($kq->{operands}->[0]), @param
  );
};


sub to_string {
  my $self = shift;
  my $str = 'length(';
  $str .= $self->{min} // '0';
  $str .= '-';
  $str .= $self->{max} // 'inf';
  $str .= ';' . $self->{token} if $self->{token};
  $str .= ':';
  $str .= $self->operand->to_string;
  return $str . ')';
};


sub is_optional {
  my $self = shift;
  if ($self->{min} == 0 && $self->operand->is_optional) {
    return 1;
  };
  return;
};


sub is_null {
  return 1 if $_[0]->{max} == 0;
  return $_[0]->operand->is_null
};


1;
