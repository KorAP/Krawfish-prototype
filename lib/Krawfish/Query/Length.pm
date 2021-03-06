package Krawfish::Query::Length;
use strict;
use warnings;
use Role::Tiny::With;
use Krawfish::Log;

with 'Krawfish::Query';

use constant DEBUG => 0;

# TODO:
#   Support RepetitionPattern, so the length query can
#   be used for contains([]{2,6}{1,2}, <base/s=s>)

# TODO:
#   This should respect different tokenizations!

# Constructor
sub new {
  my $class = shift;
  bless {
    span    => shift,
    min     => shift // 0,
    max     => shift,
    tokens  => shift,
    current => undef
  }, $class;
};


# Clone query
sub clone {
  my $self = shift;
  __PACKAGE__->new(
    $self->{span}->clone,
    $self->{min},
    $self->{max},
    $self->{tokens},
  );
};


# Move to next posting
sub next {
  my $self = shift;

  my $span = $self->{span};

  # Check if the length is between the given boundaries
  while ($span->next) {

    # Get current span
    my $current = $span->current;

    my $length = $current->end - $current->start;

    print_log('length', "Check length $length") if DEBUG;

    # Max is given
    if ($self->{max}) {

      # min and max are identical
      if ($self->{min} == $self->{max} && $length == $self->{min}) {

        if (DEBUG) {
          print_log(
            'length',
            "! Length $length has the length " . $self->{min}
          );
        };

        $self->{current} = $current;
        return 1;
      }

      # in min and max
      elsif ($length >= $self->{min} && $length <= $self->{max}) {

        if (DEBUG) {
          print_log(
            'length',
            "! Length $length is between " . $self->{min} . '-' . $self->{max}
          );
        };

        $self->{current} = $current;
        return 1;
      };
    }

    # length >= min
    elsif ($length > $self->{min}) {

      print_log('length', '! Length is larger than ' . $self->{min}) if DEBUG;

      $self->{current} = $current;
      return 1;
    };
  };

  $self->{current} = undef;
  return 0;
};


# Get current posting
sub current {
  return $_[0]->{current};
};


# Get maximum frequency
sub max_freq {
  $_[0]->{span}->max_freq;
};


# Filter query by VC
sub filter_by {
  my ($self, $corpus) = @_;
  $self->{span} = $self->{span}->filter_by($corpus);
  $self;
};


# Requires filter
sub requires_filter {
  $_[0]->{span}->requires_filter;
};


# Stringification
sub to_string {
  my $self = shift;
  my $str = 'length(';
  $str .= $self->{min} . '-' . $self->{max};
  $str .= ';' . $self->{token} if $self->{token};
  $str .= ':' . $self->{span}->to_string;
  return $str . ')';
};

1;
