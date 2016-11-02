package Krawfish::Koral::Query::Builder;
use Krawfish::Koral::Query::Token;
use Krawfish::Koral::Query::Span;
use Krawfish::Koral::Query::Sequence;
use Krawfish::Koral::Query::Position;

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


# Token construct
# Should probably be like:
# ->token('Der') or
# ->token(->term_or('Der', 'Die', 'Das'))
sub token {
  shift;
  return Krawfish::Koral::Query::Token->new(@_);
};


# Span construct
sub span {
  shift;
  return Krawfish::Koral::Query::Span->new(@_);
};


# Position construct
sub position {
  shift;
  return Krawfish::Koral::Query::Position->new(0, @_);
};

# Position construct
sub position_exclude {
  shift;
  return Krawfish::Koral::Query::Position->new(1, @_);
};

1;
