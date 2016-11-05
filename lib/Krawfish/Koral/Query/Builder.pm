package Krawfish::Koral::Query::Builder;
use Krawfish::Info;
use Krawfish::Koral::Query::Token;
use Krawfish::Koral::Query::Span;
use Krawfish::Koral::Query::Sequence;
use Krawfish::Koral::Query::Position;

sub new {
  my $class = shift;
  bless [
    shift // Krawfish::Info->new
  ], $class;
};

sub reset {
  my $self = shift;
  $self->[0] = shift // Krawfish::Info->new;
  return $self;
};

#########################
# KoralQuery constructs #
#########################

# Sequence construct
sub seq {
  my $self = shift;
  my $seq = Krawfish::Koral::Query::Sequence->new(@_);
  return $seq->info($self->[0]);
};


# Token construct
# Should probably be like:
# ->token('Der') or
# ->token(->term_or('Der', 'Die', 'Das'))
sub token {
  my $self = shift;
  my $token = Krawfish::Koral::Query::Token->new(@_);
  return $token->info($self->[0]);
};


# Span construct
sub span {
  my $self = shift;
  my $span = Krawfish::Koral::Query::Span->new(@_);
  return $span->info($self->[0]);
};


# Position construct
sub position {
  my $self = shift;
  my $pos = Krawfish::Koral::Query::Position->new(0, @_);
  return $pos->info($self->[0]);
};

# Position construct
sub position_exclude {
  my $self = shift;
  my $pos_ex = Krawfish::Koral::Query::Position->new(1, @_);
  return $pos_ex->info($self->[0]);
};

# Null element - only for plan testing purposes
sub null {
  my $token = Krawfish::Koral::Query::Token->new;
  $token->{null} = 1;
  return $token->info($_[0]->[0]);
};

1;
