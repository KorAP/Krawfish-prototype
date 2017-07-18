package Krawfish::Koral::Query::Constraint::Position;
use Krawfish::Query::Constraint::Position;
use strict;
use warnings;

# TODO:
#   Add error etc. and base this on Krawfish::Query::Constraint::Base.

# TODO:
#   It should be noted that optimization should
#   keep skip_position() in mind. so in situations
#   like <a><b>, the <b> can be skiped to a position
#   equal to the end of <a>, while <a> can't be skipped
#   to end at the beginning of <b>.

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
  my $frames = _to_frame(@_);
  bless \$frames, $class;
};

sub frames {
  ${$_[0]};
};

sub type {
  'constr_pos';
};

sub to_string {
  my $self = shift;
  return 'pos=' . join(';', _to_list($$self));
};

# List all positions of a frame
sub _to_list {
  my $frame = shift;
  my @array = ();
  while (my ($key, $value) = each %FRAME) {
    push @array, $key if $frame & $value;
  };
  return sort @array;
};


# Get the frame of a position list
sub _to_frame {

  my $frame = NULL_4;

  # Iterate over all frames
  foreach (@_) {

    # Unify with frames
    if (defined $FRAME{$_}) {
      $frame |= $FRAME{$_};
    }
    else {
      warn "Unknown frame title '$_'!"
    };
  };

  return $frame;
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


sub optimize {
  my $self = shift;
  Krawfish::Query::Constraint::Position->new($$self);
};


1;
