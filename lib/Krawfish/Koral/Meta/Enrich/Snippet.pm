package Krawfish::Koral::Meta::Enrich::Snippet;
use Krawfish::Koral::Meta::Enrich::Snippet::Match;
use Krawfish::Koral::Meta::Node::Enrich::Snippet;
use strict;
use warnings;

# TODO:
#   Define the context and the annotations
#   to retrieve for a match
#
# TODO:
#   Define annotations to retrieve for a match
#
# TODO:
#   Define highlights to retrieve for a match.

sub new {
  my $class = shift;

  # Receive options
  my $self = { @_ };
  bless $self, $class;
};

sub type {
  'snippet'
};


# Get left context object
sub left_context {
  my $self = shift;
  if (ref $self->{context} eq 'ARRAY') {
    return $self->{context}->[0];
  };
  return $self->{context};
};


# Get right context object
sub right_context {
  my $self = shift;
  if (ref $self->{context} eq 'ARRAY') {
    return $self->{context}->[1];
  };
  return $self->{context};
};


# Get match object
sub match {
  my $self = shift;
  if ($self->{match}) {
    return $self->{match};
  };

  # Create empty match object
  $self->{match} = Krawfish::Koral::Meta::Enrich::Snippet::Match->new;
  return $self->{match};
};


# TODO:
#   Normalize contexts here!
sub normalize {
  $_[0];
};


# Stringification
sub to_string {
  my $self = shift;
  my $str = 'snippet=[';
  if ($self->left_context) {
    $str .= 'left:' . $self->left_context->to_string . ',';
  };

  if ($self->right_context) {
    $str .= 'right:' . $self->right_context->to_string . ',';
  };
  $str .= $self->match->to_string;

  return $str . ']';
};


# Wrap the query
sub wrap {
  my ($self, $query) = @_;
    return Krawfish::Koral::Meta::Node::Enrich::Snippet->new(
    query => $query,
    left  => $self->left_context,
    right => $self->right_context,
    match => $self->match
  );
};


1;
