package Krawfish::Query::Constraint::Length;
use strict;
use warnings;

# TODO: This should respect different tokenizations!

sub new {
  my $class = shift;
  bless {
    span => shift,
    min => shift,
    max => shift,
    tokens => shift
  }, $class;
};

# Overwrite
sub next {
  my $self = shift;

  my $span = $self->{span};

  # Check if the length is between the given boundaries
  while ($span->next) {

    my $current = $span->current;

    if (
      ($current->start + $self->min <= $current->end) &&
        ($current->start + $self->max >= $current->end)
      ) {
      $self->{current} = $current;
      return 1;
    };
  };

  $self->{current} = undef;
  return 0;
};


sub current {
  return $_[0]->{current};
};

sub start {
  return $_[0]->{current}->start;
};

sub end {
  return $_[0]->{current}->end;
};

sub payload {
  return $_[0]->{current}->payload;
};

sub doc_id {
  return $_[0]->{current}->doc_id;
};


sub to_string {
  my $self = shift;
  my $str = 'length(';
  $str .= $self->{min} . '-' . $self->{max};
  $str .= ';' . $self->{token} if $self->{token};
  $str .= ':' . $self->{span}->to_string;
  return $str . ')';
};

1;
