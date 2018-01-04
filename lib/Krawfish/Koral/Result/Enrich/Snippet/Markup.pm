package Krawfish::Koral::Result::Enrich::Snippet::Markup;
use strict;
use warnings;
use Scalar::Util qw/blessed/;
use Role::Tiny;

requires qw/start
            end
            start_char
            end_char
            to_specific_string
            clone/;

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
  return $self->{start} // 0;
};


# End position
sub end {
  my $self = shift;
  if (@_) {
    $self->{end} = shift;
    return $self;
  };
  return $self->{end} // 0;
};


# Start char
sub start_char {
  my $self = shift;
  if (@_) {
    $self->{start_char} = shift;
    return $self;
  };
  return $self->{start_char} // 0;
};


# End char
sub end_char {
  my $self = shift;
  if (@_) {
    $self->{end_char} = shift;
    return $self;
  };
  return $self->{end_char} // 0;
};


# The element occurs as an opening tag
sub is_opening {
  my $self = shift;
  if (@_ > 0) {
    $self->{opening} = shift ? 1 : 0;
    return $self;
  };
  return $self->{opening} // 0;
};


# The element is empty
sub is_empty {
  0;
};


# Sort opening tags
#    - by start position
#    - by start character extension
#    - by end position
#    - by class number / depth
#    - by annotation term
#    - by certainty
sub compare_open {
  my ($self_a, $self_b) = @_;

  # By start position
  if ($self_a->start < $self_b->start) {
    return -1;
  }

  elsif ($self_a->start > $self_b->start) {
    return 1;
  }

  # By start character
  elsif ($self_a->start_char < $self_b->start_char){
    return -1;
  }

  elsif ($self_a->start_char > $self_b->start_char) {
    return 1;
  }

  # By end position
  elsif ($self_a->end > $self_b->end) {
    return -1;
  }

  elsif ($self_a->end < $self_b->end) {
    return 1;
  }

  # By number
  elsif ($self_a->number < $self_b->number) {
    return -1;
  }

  elsif ($self_a->number > $self_b->number) {
    return 1;
  }

  # By depth
  elsif ($self_a->depth < $self_b->depth) {
    return -1;
  }

  elsif ($self_a->depth > $self_b->depth) {
    return 1;
  }

  # By annotation term
  elsif ($self_a->term lt $self_b->term) {
    return -1;
  }

  elsif ($self_a->term gt $self_b->term) {
    return 1;
  }

  # By certainty
  elsif ($self_a->certainty < $self_b->certainty) {
    return -1;
  }

  elsif ($self_a->certainty > $self_b->certainty) {
    return 1;
  };

  return 0;
};


# Sort closing tags
#    - by end position
#    - by end character extension
#    - by start position
#    - by class number /depth
#    - by annotation term
#    - by certainty
sub compare_close {
  my ($self_a, $self_b) = @_;

  # By end position
  if ($self_a->end < $self_b->end) {
    return -1;
  }

  elsif ($self_a->end > $self_b->end) {
    return 1;
  }

  # By end character
  elsif ($self_a->end_char < $self_b->end_char){
    return -1;
  }

  elsif ($self_a->end_char > $self_b->end_char) {
    return 1;
  }

  # By start position
  elsif ($self_a->start > $self_b->start) {
    return -1;
  }

  elsif ($self_a->start < $self_b->start) {
    return 1;
  }

  # By number
  elsif ($self_a->number < $self_b->number) {
    return 1;
  }

  elsif ($self_a->number > $self_b->number) {
    return -1;
  }

  # By depth
  elsif ($self_a->depth < $self_b->depth) {
    return 1;
  }

  elsif ($self_a->depth > $self_b->depth) {
    return -1;
  }

  # By annotation term
  elsif ($self_a->term lt $self_b->term) {
    return 1;
  }

  elsif ($self_a->term gt $self_b->term) {
    return -1;
  }

  # By certainty
  elsif ($self_a->certainty < $self_b->certainty) {
    return 1;
  }

  elsif ($self_a->certainty > $self_b->certainty) {
    return -1;
  };

  return 0;
};

# Fake number for comparation
sub number {
  -1;
};


# Fake depth for comparation
sub depth {
  -1;
};


# Fake certainty for comparation
sub certainty {
  0;
};

sub term {
  '';
};


# Clone markup
sub clone {
  my $self = shift;

  return blessed($self)->new(
    start => $self->start,
    end => $self->end,
    start_char => $self->start_char,
    end_char => $self->end_char,
    opening => $self->is_opening
  );
};


# Stringification
sub to_string {
  my $self = shift;
  my $str = '';
  $str .= '(' if $self->is_opening;
  $str .= $self->to_specific_string;
  $str .= join(',', map { $_ ? $_ : 0} @{$self}{qw/start start_char end end_char/});
  $str .= ')' if !$self->is_opening;
  return $str;
};


1;
