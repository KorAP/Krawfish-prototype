package Krawfish::Result::MatchLength;
use parent 'Krawfish::Result';
use Krawfish::Log;
use strict;
use warnings;

use constant DEBUG => 0;

# This will check the segments length -
# currently other word lengths are not supported
#
# The s

sub new {
  my $class = shift;
  bless {
    query => shift,
    count => 0,
    value => undef,
    min   => 32_000,
    max   => 0,
    sum   => 0,
    freq  => 0
  }, $class;
};


sub next {
  my $self = shift;
  if ($self->{query}->next) {
    my $length = $self->{end} - $self->{start};
    $self->{min} = $length < $self->{min} ? $length : $self->{min};
    $self->{max} = $length > $self->{max} ? $length : $self->{max};
    $self->{sum} += $length;
    $self->{freq}++;
    return 1;
  };
  return 0;
};


sub match_lengths {
  my $self = shift;
  return unless $self->{freq};
  return {
    min  => $self->{min},
    max  => $self->{max},
    sum  => $self->{sum},
    freq => $self->{freq},
    avg  => $self->{sum} / $self->{freq}
  };
};


1;
