package Krawfish::Query::Length;
use Krawfish::Log;
use strict;
use warnings;

use constant DEBUG => 0;

# TODO: This should respect different tokenizations!

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

# Overwrite
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

        print_log('length', "! Length $length has the length " . $self->{min}) if DEBUG;

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


sub freq {
  $_[0]->{span}->freq;
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
