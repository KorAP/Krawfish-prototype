package Krawfish::Koral::Query::Extension;
use parent 'Krawfish::Koral::Query';
use strict;
use warnings;

sub new {
  my $class = shift;
  my $self = $class->SUPER::new;
  $self->{direction} = shift;
  $self->{anchor} = shift;
  $self->{extension} = shift;
  return $self;
};

sub plan_for {
  ...
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
