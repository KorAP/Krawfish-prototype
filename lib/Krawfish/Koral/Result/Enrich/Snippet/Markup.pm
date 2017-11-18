package Krawfish::Koral::Result::Enrich::Snippet::Markup;
use strict;
use warnings;
use Role::Tiny;

requires qw/start
            end
            start_char
            end_char/;

# TODO:
#   Have common methods with
#   Krawfish::Koral::Document::Annotation

# TODO:
#   This is the base class for
#   - hit
#   - highlight
#   - relation
#   - anchor
#   - Annotation

# TODO:
#   All these role may very well
#   be under Koral - as index data types.

sub new {
  my $class = shift;
  bless { @_ }, $class;
};


# Start position
sub start {
  my $self = shift;
  if (@_) {
    $self->{start} = shift;
    return $self;
  };
  return $self->{start};
};


# End position
sub end {
  my $self = shift;
  if (@_) {
    $self->{end} = shift;
    return $self;
  };
  return $self->{end};
};


# Start char
sub start_char {
  my $self = shift;
  if (@_) {
    $self->{start_char} = shift;
    return $self;
  };
  return $self->{start_char};
};


# End char
sub end_char {
  my $self = shift;
  if (@_) {
    $self->{end_char} = shift;
    return $self;
  };
  return $self->{end_char};
};


# The element occurs as an opening tag
sub is_opening {
  my $self = shift;
  if (@_ > 0) {
    $self->{opening} = shift;
    return $self;
  };
  return $self->{opening};
};

1;
