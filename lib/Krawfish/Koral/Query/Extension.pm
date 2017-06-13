package Krawfish::Koral::Query::Extension;
use parent 'Krawfish::Koral::Query';
use strict;
use warnings;


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
  $self->{anchor} = shift;
  $self->{extension} = shift;
  return $self;
};


sub plan_for {
  my $self = shift;
  my $index = shift;

  my $anchor = $self->{anchor};
  my $ext = $self->{extension};

  # Extension is not important
  if ($ext->is_null) {
    return $anchor->plan_for($index);
  };

  if ($ext->is_optional) {
    if ($ext->is_negative) {
      ...
    };

    # if ($ext->is_partially_negative) {
    #   ...
    # }

    if ($ext->is_any) {
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

  if ($ext->is_any) {
    ...
  };
};

sub to_string {
  my $self = shift;
  my $string = 'ext(';
  $string .= 0 + $self->{direction};
  $string .= ':';
  $string .= $self->{anchor}->to_string;
  $string .= ',' . $self->{extension}->to_string;
  $string .= ')';
};

1;
