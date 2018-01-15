package Krawfish::Koral::Result::Enrich::Snippet::Highlight;
use strict;
use warnings;
use Role::Tiny::With;
use Krawfish::Log;

with 'Krawfish::Koral::Result::Enrich::Snippet::Markup';

use constant DEBUG => 0;


sub type {
  'highlight'
}

# Class number of highlight
sub number {
  my $self = shift;
  if (@_) {
    $self->{number} = shift;
    return $self;
  };
  return $self->{number};
};


# Level of the highlight
sub level {
  my $self = shift;
  if (@_) {
    $self->{level} = shift;
    return $self;
  };
  return $self->{level} // '?';
};


# Stringify to brackets
sub to_brackets {
  my $self = shift;
  return '}' unless $self->is_opening;
  return '{' . $self->number .':' if $self->number;
};


sub to_html {
  my $self = shift;
  return '</mark>' unless $self->is_opening;
  my $str = '<mark';
  if ($self->number) {
    $str .= ' class="class-' . $self->number . ' level-' . $self->level . '"';
  };
  return $str . '>';
};


sub clone {
  my $self = shift;
  return __PACKAGE__->new(
    start => $self->start,
    end => $self->end,
    start_char => $self->start_char,
    end_char => $self->end_char,
    start_abs => $self->start_abs,
    end_abs => $self->end_abs,
    opening => $self->is_opening,
    terminal => $self->is_terminal,
    number => $self->number
  );
};

sub to_specific_string {
  return $_[0]->type . ':' . $_[0]->number;
};

1;
