package Krawfish::Koral::Result::Aggregate::Length;
use Krawfish::Util::Bits;
use strict;
use warnings;

# This calculates match length for all
# corpus classes.

# TODO:
#   Rename "class1" etc. to "inCorpus1"

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



# Finish the calculation
sub on_finish {
  $_[0];
};


# Stringification
sub to_string {
  my $self = shift;
  my $str = '[length=';
  my @classes = @{$self->_to_classes};
  my $first = 0;
  foreach (my $i = 0; $i < @classes; $i++) {

    my $length = $classes[$i];
    $str .= $i == 0 ? 'total' : 'class' . $i;
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


sub key {
  'length';
};


1;
