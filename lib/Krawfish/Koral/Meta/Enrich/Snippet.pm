package Krawfish::Koral::Meta::Enrich::Snippet;
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

sub left_context {
  my $self = shift;
  if (ref $self->{context} eq 'ARRAY') {
    return $self->{context}->[0];
  };
  return $self->{context};
};


sub right_context {
  my $self = shift;
  if (ref $self->{context} eq 'ARRAY') {
    return $self->{context}->[1];
  };
  return $self->{context};
};

sub normalize {
  $_[0];
};


sub to_string {
  my $self = shift;
  my $str = 'snippet=[';
  if ($self->left_context) {
    $str .= 'left:' . $self->left_context->to_string . ',';
  };

  if ($self->right_context) {
    $str .= 'right:' . $self->right_context->to_string . ',';
  };
  $str .= 'match';

  return $str . ']';
};


# Wrap the query
sub wrap {
  my ($self, $query) = @_;
    return Krawfish::Koral::Meta::Node::Enrich::Snippet->new(
    query => $query,
    left => $self->left_context,
    right => $self->right_context
  );
};

1;
