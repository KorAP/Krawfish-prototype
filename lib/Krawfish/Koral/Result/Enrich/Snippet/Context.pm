package Krawfish::Koral::Result::Enrich::Snippet::Context;
use strict;
use warnings;
use Role::Tiny::With;

with 'Krawfish::Koral::Result::Enrich::Snippet::Markup';

sub type {
  return 'context'
};


# Left or right context
# Defaults to right
sub left {
  my $self = shift;
  if (@_) {
    $self->{left} = shift;
    return $self;
  };
  return $self->{left} // 0;
};


# Close element before next element starts
# This overrides any end-parameter
sub end_before_next {
  $_[0]->left;
};

# Clone context object (Probably unused)
sub clone {
  my $self = shift;
  return __PACKAGE__->new(
    start => $self->start,
    end => $self->end,
    start_char => $self->start_char,
    end_char => $self->end_char,
    opening => $self->is_opening,
    terminal => $self->is_terminal,
    left => $self->left,
    end_before_next => $self->end_before_next
  );
};


# Return specific string for stringification
sub to_specific_string {
  $_[0]->type . '-' . $_[0]->left
};


# Serialize to brackets
sub to_brackets {
  '';
};


# Serialize to HTML
sub to_html {
  my $self = shift;
  return '</span>' unless $self->is_opening;

  my $str = '<span class="context-';
  $str .= $self->left ? 'left' : 'right';
  return $str . '">';
};


1;
