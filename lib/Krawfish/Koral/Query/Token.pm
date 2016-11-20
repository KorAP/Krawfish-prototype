package Krawfish::Koral::Query::Token;
use parent 'Krawfish::Koral::Query';
use Krawfish::Koral::Query::Token;
use Krawfish::Koral::Query::Term;
use Krawfish::Query::Term;
use strict;
use warnings;
use Scalar::Util qw/blessed/;

# TODO: Support multiple tokens in a term group!

sub new {
  my $class = shift;
  my $token = shift;

  # Any token
  unless ($token) {
    return bless { wrap => undef }, $class;
  };

  # Token is a string
  unless (blessed $token) {
    return bless {
      wrap => Krawfish::Koral::Query::Term->new($token)
    }, $class;
  };

  # Token is already a group or a term
  bless {
    wrap => $token
  };
};

sub type { 'token' };

sub wrap {
  $_[0]->{wrap};
};


# Return Koral fragment
sub to_koral_fragment {
  my $self = shift;

  my $token = {
    '@type' => 'koral:token'
  };

  if ($self->wrap) {
    $token->{wrap} = $self->wrap->to_koral_fragment;
  };

  $token;
};


# Overwrite is any
sub is_any {
  return 1 unless $_[0]->wrap;
  return;
};


# Query planning
sub plan_for {
  my ($self, $index) = @_;

  # Token is null
  if ($self->is_null) {
    $self->error(000, 'Unable to search for null tokens');
    return;
  };

  # No term defined
  unless ($self->wrap) {
    $self->error(000, 'Unable to search for any tokens');
    return;
  };

  # Create token query
  if ($self->wrap->type eq 'term') {
    return Krawfish::Query::Term->new(
      $index,
      $self->wrap->to_string
    );
  };

  return $self->wrap->plan_for($index);
};


# Stringify
sub to_string {
  my $string = '[' . ($_[0]->wrap ? $_[0]->wrap->to_string : '') . ']';
  if ($_[0]->is_null) {
    $string .= '{0}';
  }
  elsif ($_[0]->is_optional) {
    $string .= '?';
  };
  return $string;
};


sub maybe_unsorted { 0 };


1;
