package Krawfish::Koral::Query::Builder;
use Krawfish::Util::Constants qw/:PREFIX/;
use Krawfish::Util::Bits;

use Krawfish::Koral::Query::Term;
use Krawfish::Koral::Query::Token;
use Krawfish::Koral::Query::Span;
use Krawfish::Koral::Query::InCorpus;
use Krawfish::Koral::Query::Sequence;
use Krawfish::Koral::Query::Repetition;
use Krawfish::Koral::Query::TermGroup;
use Krawfish::Koral::Query::Extension;
use Krawfish::Koral::Query::Exclusion;
use Krawfish::Koral::Query::Unique;
use Krawfish::Koral::Query::Class;
use Krawfish::Koral::Query::Constraint;
use Krawfish::Koral::Query::Length;
use Krawfish::Koral::Query::Nowhere;
use Krawfish::Koral::Query::Or;
use Krawfish::Koral::Query::Filter;
use Krawfish::Koral::Query::Match;

# TODO: Not all constraints need to be wrapped
use Krawfish::Koral::Query::Constraint::Position;
use Krawfish::Koral::Query::Constraint::ClassBetween;
use Krawfish::Koral::Query::Constraint::NotBetween;
use Krawfish::Koral::Query::Constraint::InBetween;

use Krawfish::Koral::Corpus::Builder;

use Scalar::Util qw/blessed/;
use strict;
use warnings;

use constant DOC_IDENTIFIER => 'id';

sub new {
  my $class = shift;
  my $text_span = shift // 'base/s=t';
  bless [$text_span], $class;
};


#########################
# KoralQuery constructs #
#########################


# Token construct
# Should probably be like:
# ->token('Der') or
# ->token(->term_or('Der', 'Die', 'Das'))
sub token {
  shift;
  return Krawfish::Koral::Query::Token->new(@_);
};


sub class {
  shift;
  Krawfish::Koral::Query::Class->new(@_);
};

# Sequence construct
sub seq {
  shift;
  return Krawfish::Koral::Query::Sequence->new(@_);
};


sub repeat {
  shift;
  return Krawfish::Koral::Query::Repetition->new(@_);
};


sub term {
  shift;
  return Krawfish::Koral::Query::Term->new(TOKEN_PREF . shift);
};

sub term_neg {
  shift;
  Krawfish::Koral::Query::Term->new(@_)->match('!=');
};

sub term_re {
  shift;
  Krawfish::Koral::Query::Term->new(@_)->match('~');
};


sub bool_and {
  shift;
  Krawfish::Koral::Query::TermGroup->new('and' => @_);
};

sub bool_and_not {
  shift;
  my ($pos, $neg) = @_;
  Krawfish::Koral::Query::Exclusion->new(['matches'], $pos, $neg);
};


sub bool_or {
  my $self = shift;
  my $first_type = blessed $_[0] ? $_[0]->type : 'term';
  my $second_type = blessed $_[1] ? $_[1]->type : 'term';
  if (
    ($first_type eq 'term' || $first_type eq 'termGroup') &&
      ($second_type eq 'term' || $second_type eq 'termGroup')
    ) {
    return Krawfish::Koral::Query::TermGroup->new('or' => @_);
  };

  return Krawfish::Koral::Query::Or->new(@_);
};


# Span construct
sub span {
  shift;
  Krawfish::Koral::Query::Span->new(@_);
};


# Create an in-text construct
sub in_text {
  my $self = shift;
  return $self->position(
    ['endsWith', 'isAround', 'startsWith', 'matches'],
    $self->span($self->[0]),
    shift
  );
};


# Position construct
sub position {
  my $self = shift;
  my $frames = shift;
  return $self->constraint(
    [$self->c_position(@$frames)],
    @_
  );
};


# Position construct
sub exclusion {
  shift;
  Krawfish::Koral::Query::Exclusion->new(@_);
};


# Search with reference to a specific supcorpus
sub in_corpus {
  shift;
  Krawfish::Koral::Query::InCorpus->new(@_);
};


# Create reference query
sub reference {
  shift;
  Krawfish::Koral::Query::Reference->new(shift);
};


sub constraint {
  shift;
  Krawfish::Koral::Query::Constraint->new(@_);
};

sub c_position {
  shift;
  Krawfish::Koral::Query::Constraint::Position->new(@_);
};

sub c_class_between {
  shift;
  Krawfish::Koral::Query::Constraint::ClassBetween->new(@_);
};

sub c_not_between {
  shift;
  Krawfish::Koral::Query::Constraint::NotBetween->new(@_);
};

sub c_in_between {
  shift;
  Krawfish::Koral::Query::Constraint::InBetween->new(@_);
};


# Make all positions be in order
sub c_in_order {
  shift;
  Krawfish::Koral::Query::Constraint::Position->new(
    qw/precedesDirectly precedes endsWith isAround overlapsLeft alignsLeft matches/
  );
};


sub length {
  shift;
  Krawfish::Koral::Query::Length->new(@_);
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


# Matches anywhere
sub anywhere {
  Krawfish::Koral::Query::Token->new;
};


# Null element - only for plan testing purposes
sub null {
  Krawfish::Koral::Query::Term->new;
};


# No match
sub nowhere {
  Krawfish::Koral::Query::Nowhere->new;
};


# Unique results
sub unique {
  shift;
  Krawfish::Koral::Query::Unique->new(@_);
};


# Filter a query with a corpus
sub filter_by {
  shift;
  Krawfish::Koral::Query::Filter->new(@_);
};


# Find exactly one single match
sub match {
  my $self = shift;
  my ($doc_id, $start, $end, $pl, $flags) = @_;

  my $cb = Krawfish::Koral::Corpus::Builder->new;
  my $doc = $cb->string(DOC_IDENTIFIER)->eq($doc_id);

  my $payload;
  if ($pl) {
    $payload = Krawfish::Posting::Payload->new;
    foreach (@$pl) {
      $payload->add(@{$_});
    };
  };

  if ($flags && ref($flags) eq 'ARRAY') {
    $flags = classes_to_flags(@$flags)
  };

  Krawfish::Koral::Query::Match->new(
    $doc,
    $start,
    $end,
    $payload,
    $flags
  );
};


##############################
# KoralQuery deserialization #
##############################

# Deserialize
sub from_koral {
  my ($self, $kq) = @_;

  my $type = $kq->{'@type'};

  # Deserialize groups
  if ($type eq 'koral:group') {
    my $op = $kq->{operation};

    # Check for operation types
    if ($op eq 'operation:sequence') {
      return Krawfish::Koral::Query::Sequence->from_koral($kq);
    }

    elsif ($op eq 'operation:class') {
      return Krawfish::Koral::Query::Class->from_koral($kq);
    }

    elsif ($op eq 'operation:length') {
      return Krawfish::Koral::Query::Length->from_koral($kq);
    }

    elsif ($op eq 'operation:repetition') {
      return Krawfish::Koral::Query::Repetition->from_koral($kq);
    }

    elsif ($op eq 'operation:exclusion') {
      return Krawfish::Koral::Query::Exclusion->from_koral($kq);
    }

    elsif ($op eq 'operation:position' || $op eq 'operation:constraint') {
      return Krawfish::Koral::Query::Constraint->from_koral($kq);
    }

    elsif ($op eq 'operation:disjunction' || $op eq 'operation:or') {
      return Krawfish::Koral::Query::Or->from_koral($kq);
    }

    elsif ($op eq 'operation:unique') {
      return Krawfish::Koral::Query::Unique->from_koral($kq);
    }

    else {
      warn 'Operation ' . $op . ' no supported';
    };
  }

  elsif ($type eq 'koral:token') {
    return Krawfish::Koral::Query::Token->from_koral($kq);
  }

  elsif ($type eq 'koral:match') {
    return Krawfish::Koral::Query::Match->from_koral($kq);
  }

  elsif ($type eq 'koral:span') {
    return Krawfish::Koral::Query::Span->from_koral($kq);
  }

  elsif ($type eq 'koral:nowhere') {
    return Krawfish::Koral::Query::Nowhere->from_koral;
  }

  else {
    warn $type . ' unknown';
  };

  return;
};


sub from_koral_constraint {
  shift;
  my $kq = shift;
  if ($kq->{'@type'} eq 'constraint:position') {
    return Krawfish::Koral::Query::Constraint::Position->from_koral($kq);
  }

  elsif ($kq->{'@type'} eq 'constraint:classBetween') {
    return Krawfish::Koral::Query::Constraint::ClassBetween->from_koral($kq);
  }

  elsif ($kq->{'@type'} eq 'constraint:notBetween') {
    return Krawfish::Koral::Query::Constraint::NotBetween->from_koral($kq);
  }

  elsif ($kq->{'@type'} eq 'constraint:inBetween') {
    return Krawfish::Koral::Query::Constraint::InBetween->from_koral($kq);
  };

  warn 'Type ' . $kq->{'@type'} . ' unknown';
};


# Deserialize from term or term group
sub from_koral_term_or_term_group {
  my ($self, $kq) = @_;
  my $type = $kq->{'@type'};

  # Defines a term
  if ($type eq 'koral:term') {
    return $self->from_koral_term($kq);
  }

  # Defines a term group
  elsif ($type eq 'koral:termGroup') {
    return Krawfish::Koral::Query::TermGroup->from_koral($kq);
  }

  # Matches nowhere
  elsif ($type eq 'koral:nowhere') {
    return Krawfish::Koral::Query::Nowhere->from_koral;
  };

  warn 'Not term or termGroup: ' . $kq->{'@type'};

  return;
};


# Get from koral:term
sub from_koral_term {
  my ($self, $kq) = @_;

  if (defined $kq->{'@id'}) {
    return Krawfish::Koral::Query::TermID->from_koral($kq);
  };

  return Krawfish::Koral::Query::Term->from_koral($kq);
};


1;
