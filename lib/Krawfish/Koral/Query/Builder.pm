package Krawfish::Koral::Query::Builder;
use Krawfish::Koral::Query::Token;
use Krawfish::Koral::Query::Span;
use Krawfish::Koral::Query::Sequence;
use Krawfish::Koral::Query::Repetition;
use Krawfish::Koral::Query::Position;
use Krawfish::Koral::Query::Extension;

sub new {
  my $class = shift;
  bless [], $class;
};

#########################
# KoralQuery constructs #
#########################

# Sequence construct
sub seq {
  shift;
  return Krawfish::Koral::Query::Sequence->new(@_);
};


sub repeat {
  shift;
  return Krawfish::Koral::Query::Repetition->new(@_);
};


# Token construct
# Should probably be like:
# ->token('Der') or
# ->token(->term_or('Der', 'Die', 'Das'))
sub token {
  shift;
  Krawfish::Koral::Query::Token->new(@_);
};


# Span construct
sub span {
  shift;
  Krawfish::Koral::Query::Span->new(@_);
};


# Position construct
sub position {
  shift;
  Krawfish::Koral::Query::Position->new(0, @_);
};

# Position construct
sub position_exclude {
  shift;
  Krawfish::Koral::Query::Position->new(1, @_);
};

# Extension to the left
sub ext_left {
  shift;
  Krawfish::Koral::Query::Extension->new(0, @_);
};

sub ext_right {
  shift;
  Krawfish::Koral::Query::Extension->new(1, @_);
};


# Null element - only for plan testing purposes
sub null {
  my $token = Krawfish::Koral::Query::Token->new;
  $token->{null} = 1;
  return $token;
};

1;
