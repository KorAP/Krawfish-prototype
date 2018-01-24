package Krawfish::Koral::Compile::Enrich::Snippet;
use Krawfish::Koral::Compile::Node::Enrich::Snippet;
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


sub highlights {
  $_[0]->{highlights};
};


sub format {
  $_[0]->{format};
};


# TODO:
#   Normalize contexts here!
sub normalize {
  $_[0];
};


# Stringification
sub to_string {
  my ($self, $id) = @_;
  my $str = 'snippet=[';

  $str .= 'hit';

  if ($self->left_context) {
    $str .= ',left:' . $self->left_context->to_string($id);
  };

  if ($self->right_context) {
    $str .= ',right:' . $self->right_context->to_string($id);
  };

  if ($self->highlights) {
    $str .= ',hls:[' . join(',',@{$self->highlights}) . ']';
  };

  if ($self->{format}) {
    $str .= ',format:' . $self->{format};
  };

  return $str . ']';
};


# Wrap the query
sub wrap {
  my ($self, $query) = @_;
    return Krawfish::Koral::Compile::Node::Enrich::Snippet->new(
      query => $query,
      left  => $self->left_context,
      right => $self->right_context,
      highlights => $self->highlights,
      'format'   => $self->{format}
    # hit => $self->hit
  );
};


1;
