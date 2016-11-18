package Krawfish::Koral::Query::Builder;
use Krawfish::Koral::Query::Term;
use Krawfish::Koral::Query::Token;
use Krawfish::Koral::Query::Span;
use Krawfish::Koral::Query::Sequence;
use Krawfish::Koral::Query::Repetition;
use Krawfish::Koral::Query::TermGroup;
use Krawfish::Koral::Query::Position;
use Krawfish::Koral::Query::Extension;
use Krawfish::Koral::Query::Exclusion;
use Krawfish::Koral::Query::Unique;
use Krawfish::Koral::Query::Class;
use Krawfish::Koral::Query::Constraints;

# TODO: Not all constraints need to be wrapped
use Krawfish::Koral::Query::Constraint::Position;
use Krawfish::Koral::Query::Constraint::ClassDistance;

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

sub term {
  shift;
  Krawfish::Koral::Query::Term->new(@_);
};

sub term_and {
  shift;
  Krawfish::Koral::Query::TermGroup->new('and' => @_);
};

sub term_or {
  shift;
  Krawfish::Koral::Query::TermGroup->new('or' => @_);
};


# Span construct
sub span {
  shift;
  Krawfish::Koral::Query::Span->new(@_);
};


# Position construct
sub position {
  shift;
  Krawfish::Koral::Query::Position->new(@_);
};


# Position construct
sub exclusion {
  shift;
  Krawfish::Koral::Query::Exclusion->new(@_);
};


sub constraints {
  shift;
  Krawfish::Koral::Query::Constraints->new(@_);
};

sub c_position {
  shift;
  Krawfish::Koral::Query::Constraint::Position->new(@_);
};

sub c_class_distance {
  shift;
  Krawfish::Koral::Query::Constraint::ClassDistance->new(@_);
};

sub class {
  shift;
  Krawfish::Koral::Query::Class->new(@_);
};

# Extension to the left
sub ext_left {
  shift;
  Krawfish::Koral::Query::Extension->new(1, @_);
};

sub ext_right {
  shift;
  Krawfish::Koral::Query::Extension->new(0, @_);
};


# Null element - only for plan testing purposes
sub null {
  Krawfish::Koral::Query::Term->new;
};


# Unique results
sub unique {
  shift;
  Krawfish::Koral::Query::Unique->new(@_);
};

1;
