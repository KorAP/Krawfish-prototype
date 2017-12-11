package Krawfish::Koral::Query::Constraint::Position;
use parent 'Exporter';
use Krawfish::Query::Constraint::Position;
use feature 'state';
use strict;
use warnings;
use Memoize;
memoize('min_span');
memoize('max_span');

our @EXPORT = qw/to_frame
                 to_list
                 MATCHES/;

# TODO:
#   Add error etc. and base this on Krawfish::Query::Constraint::Base.

# TODO:
#   It should be noted that optimization should
#   keep skip_position() in mind. so in situations
#   like <a><b>, the <b> can be skiped to a position
#   equal to the end of <a>, while <a> can't be skipped
#   to end at the beginning of <b>.

use constant {
  C_NEXT      => PRECEDES_DIRECTLY | SUCCEEDS_DIRECTLY,
  C_NEXT_PLUS => PRECEDES | SUCCEEDS,
  C_MAPS      => (MATCHES | IS_AROUND | IS_WITHIN | STARTS_WITH | ENDS_WITH |
                 ALIGNS_LEFT | ALIGNS_RIGHT),
  C_MAPS_PLUS => OVERLAPS_LEFT | OVERLAPS_RIGHT
};

our %FRAME = (
  precedes => PRECEDES,
  precedesDirectly => PRECEDES_DIRECTLY,
  overlapsLeft => OVERLAPS_LEFT,
  alignsLeft => ALIGNS_LEFT,
  startsWith => STARTS_WITH,
  matches => MATCHES,
  isWithin => IS_WITHIN,
  isAround => IS_AROUND,
  endsWith => ENDS_WITH,
  alignsRight => ALIGNS_RIGHT,
  overlapsRight => OVERLAPS_RIGHT,
  succeedsDirectly => SUCCEEDS_DIRECTLY,
  succeeds => SUCCEEDS
);


sub new {
  my $class = shift;
  my $frames = to_frame(@_);
  bless \$frames, $class;
};


sub frames {
  my $self = shift;
  if ($_[0]) {
    $$self = shift;
  };
  $$self;
};


# List all positions of a frame
sub to_list {
  my $frame = shift;
  my @array = ();
  while (my ($key, $value) = each %FRAME) {
    push @array, $key if $frame & $value;
  };
  return sort @array;
};


# Get the frame of a position list
sub to_frame {

  my $frame = NULL_4;

  # Iterate over all frames
  foreach (@_) {
    my $f = $_;

    # Unify with frames

    $f =~ s/^frames://;

    if (defined $FRAME{$f}) {
      $frame |= $FRAME{$f};
    }
    else {
      warn "Unknown frame title '$f'!"
    };
  };

  return $frame;
};


sub type {
  'constr_pos';
};

sub to_string {
  my $self = shift;
  return 'pos=' . join(';', to_list($$self));
};


# Normalize options of the constraint
sub normalize {
  my $self = shift;

  # Frame is zero
  if ($$self == NULL_4) {
    # $self->error(000, 'No valid frame defined');
    return;
  };

  return $self;
};


# The minimum number of tokens for the constraint
sub min_span {
  my ($self, $first_len, $second_len) = @_;
  my $frame = $$self;

  # Check the possible configurations and return the minimum span length possible
  if ($first_len == -1 || $second_len == -1) {
    return -1;
  };

  # Return mapping
  if ($frame & C_MAPS) {
    return $first_len > $second_len ? $first_len : $second_len;
  }

  # Return mapping - at least one token overlap
  elsif ($frame & C_MAPS_PLUS) {
    return ($first_len > $second_len ? $first_len : $second_len) + 1;
  }

  # Return addition of length
  elsif ($frame & C_NEXT) {
    return $first_len + $second_len;
  }

  # Return addition of length + at least one token distance
  elsif ($frame & C_NEXT_PLUS) {
    return $first_len + $second_len + 1;
  };

  return -1;
};


# Maximum number of tokens for the constraint
sub max_span {
  my ($self, $first_len, $second_len) = @_;
  my $frame = $$self;

  # Check the possible configurations and return the maximum span length possible
  if ($first_len == -1 || $second_len == -1) {
    return -1;
  };

  # Operands can be in any distance
  if ($frame & C_NEXT_PLUS) {
    return -1;
  }

  # Operands are next to each other
  elsif ($frame & C_NEXT) {
    return $first_len + $second_len;
  }

  # Return addition of length - at least one token overlap
  elsif ($frame & C_MAPS_PLUS) {
    return $first_len + $second_len - 1;
  }

  # Operands occur on same space
  elsif ($frame & C_MAPS) {
    return $first_len > $second_len ? $first_len : $second_len;
  };

  return -1;
};


sub identify {
  $_[0];
};

sub optimize {
  my $self = shift;
  Krawfish::Query::Constraint::Position->new($$self);
};


sub from_koral {
  my ($class, $kq) = @_;
  return $class->new(@{$kq->{frames}});
};


sub to_koral_fragment {
  my $self = shift;
  return {
    '@type' => 'constraint:position',
    'frames' => [
      map { 'frames:' . $_ } to_list($$self)
    ]
  };
};

1;
