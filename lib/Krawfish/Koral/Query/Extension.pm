package Krawfish::Koral::Query::Extension;
use Role::Tiny::With;
use strict;
use warnings;

with 'Krawfish::Koral::Query';


# TODO:
#   An extension with a negative part will
#   not be part of this.
#
#     der [!alte]
#
#   will be
#
#     extend(right,excl([succeedsDirectly], der, alte))

sub new {
  my $class = shift;
  my $self = $class->SUPER::new;
  $self->{direction} = shift;
  $self->{operands} = [shift];
  $self->{extension} = shift;
  return $self;
};


sub normalize {
  my $self = shift;

  my $anchor = $self->operands->[0];
  my $ext = $self->{extension};

  # Extension is not important
  if ($ext->is_null) {
    return $anchor->normalize;
  };

  if ($ext->is_optional) {
    if ($ext->is_negative) {
      ...
    };

    # if ($ext->is_partially_negative) {
    #   ...
    # }

    if ($ext->is_anywhere) {
      ...
    };
    ...
  };

  if ($ext->is_negative) {
    ...
  };

  # if ($ext->is_partially_negative) {
  #   ...
  # };

  if ($ext->is_anywhere) {
    ...
  };
};

sub min_span {
  ...
};

sub max_span {
  ...
};

sub optimize {
  ...;
};

sub type {
  'extension';
};

sub to_koral_fragment {
  ...
};

sub from_koral {
  ...
};

sub uses_classes {
  ...
};

sub to_string {
  my $self = shift;
  my $string = 'ext(';
  $string .= 0 + $self->{direction};
  $string .= ':';
  $string .= $self->operands->[0]->to_string;
  $string .= ',' . $self->{extension}->to_string;
  $string .= ')';
};

1;
