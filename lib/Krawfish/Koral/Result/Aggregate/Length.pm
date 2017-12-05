package Krawfish::Koral::Result::Aggregate::Length;
use strict;
use warnings;
use Krawfish::Util::Bits;
use Role::Tiny::With;

with 'Krawfish::Koral::Result::Inflatable';
with 'Krawfish::Koral::Result::Aggregate';

# This calculates match length for all
# corpus classes.

# TODO:
#   It may very vell also support query
#   classes.

use constant {
  MIN_INIT_VALUE => 32_000
};


# Constructor
sub new {
  my $class = shift;
  bless {
    flags => shift,
    length => {}
  }, $class;
};


# Increment value per document
sub incr_match {
  my ($self, $length, $flags) = @_;

  my $l = ($self->{length}->{$flags} //= {
    min  => MIN_INIT_VALUE,
    max  => 0,
    sum  => 0,
    freq => 0
  });

  $l->{min} = $length < $l->{min} ? $length : $l->{min};
  $l->{max} = $length > $l->{max} ? $length : $l->{max};
  $l->{sum} += $length;
  $l->{freq}++;
};


# Merge aggregation results on node level
sub merge {
  my ($self, $aggr) = @_;

  my $length = ($self->{length} //= {});

  foreach my $flag (keys %{$aggr->{length}}) {
    my $l_flag = $length->{$flag};
    my $a_flag = $aggr->{length}->{$flag};

    if (!defined $l_flag) {
      # Set flag
      $length->{$flag} = {
        min => $a_flag->{min},
        max => $a_flag->{max},
        sum => $a_flag->{sum},
        freq => $a_flag->{freq}
      };
    }
    else {
      $l_flag->{min} = $a_flag->{min} < $l_flag->{min} ? $a_flag->{min} : $l_flag->{min};
      $l_flag->{max} = $a_flag->{max} > $l_flag->{max} ? $a_flag->{max} : $l_flag->{max};
      $l_flag->{sum} += $a_flag->{sum};
      $l_flag->{freq} += $a_flag->{freq};
    };
  };
};


# Inflate result
sub inflate {
  $_[0];
};


# Convert to class structure
sub _to_classes {
  my $self = shift;

  my $flags = $self->{length};
  my @classes;

  foreach my $flag (keys %$flags) {
    foreach my $class (flags_to_classes($flag)) {
      my $length = ($classes[$class] //= {
        min  => MIN_INIT_VALUE,
        max  => 0,
        sum  => 0,
        freq => 0
      });

      my $value = $flags->{$flag};

      $length->{sum} += $value->{sum};
      $length->{freq} += $value->{freq};
      $length->{min} = (
        $value->{min} < $length->{min} ? $value->{min} : $length->{min}
      );
      $length->{max} = (
        $value->{max} > $length->{max} ? $value->{max} : $length->{max}
      );

      # Calculate average value
      $length->{avg} = $length->{sum} / $length->{freq};
    };
  };

  return \@classes;
};


# Stringification
sub to_string {
  my $self = shift;
  my $str = '[length=';
  my @classes = @{$self->_to_classes};
  my $first = 0;
  foreach (my $i = 0; $i < @classes; $i++) {

    my $length = $classes[$i];
    $str .= $i == 0 ? 'total' : 'inCorpus-' . $i;
    $str .= ':[';
    $str .= 'avg:' .  $length->{avg} . ',';
    $str .= 'freq:' . $length->{freq} . ',';
    $str .= 'min:' .  $length->{min} . ',';
    $str .= 'max:' .  $length->{max} . ',';
    $str .= 'sum:' .  $length->{sum};
    $str .= '];';
  };
  chop $str;
  return $str . ']';
};


# Serialize to KQ
sub to_koral_fragment {
  my $self = shift;

  my $aggr = {
    '@type' => 'koral:aggregation',
    'aggregation' => 'aggregation:length'
  };

  my @classes = @{$self->_to_classes};
  my $first = 0;
  foreach (my $i = 0; $i < @classes; $i++) {
    my $length = $classes[$i];

    $aggr->{$i == 0 ? 'total' : 'inCorpus-' . $i} = {
      'avg'  =>  $length->{avg},
      'freq' => $length->{freq},
      'min'  => $length->{min},
      'max'  => $length->{max},
      'sum'  => $length->{sum}
    };
  };

  return $aggr;
};


sub key {
  'length';
};


1;
