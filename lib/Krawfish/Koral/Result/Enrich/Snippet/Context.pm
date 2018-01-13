package Krawfish::Koral::Result::Enrich::Snippet::Context;
use strict;
use warnings;
use Krawfish::Util::Constants qw/MAX_SPAN_SIZE/;
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


# There is more context available
sub more {
  my $self = shift;
  if (@_) {
    $self->{more} = shift;
    return $self;
  };
  return $self->{more} // 0;
};

sub start {
  0;
};


sub end {
  MAX_SPAN_SIZE;
};


# Close element before next element starts
# This overrides any end-parameter
sub end_before_next {
  !!$_[0]->left;
};


# Only start after all other elements are closed
sub start_after_all {
  !$_[0]->left;
};


# Clone context object
sub clone {
  my $self = shift;

  # TODO:
  #   This is probably unused
  #   and may throw a warning!
  return __PACKAGE__->new(
    start => $self->start,
    end => $self->end,
    start_char => $self->start_char,
    end_char => $self->end_char,
    opening => $self->is_opening,
    terminal => $self->is_terminal,
    left => $self->left,
    end_before_next => $self->end_before_next,
    more => $self->more
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

  # TODO:
  #   There may be the need for additional
  #   Annotations, like doc_id and start position
  #   of more contextual data

  my $str = '';

  # Close tag
  unless ($self->is_opening) {
    if (!$self->left && $self->more) {
      $str .= '<span class="more"></span>';
    };
    return $str . '</span>';
  };

  # Opening tag
  $str = '<span class="context-';
  if ($self->left) {
    $str .= 'left">';
    if ($self->more) {
      $str .= '<span class="more"></span>';
    };
  }
  else {
    $str .= 'right">';
  };

  return $str;
};


1;
