package Krawfish::Koral::Query::Importer;
use warnings;
use strict;
use Krawfish::Koral::Query;
use Krawfish::Koral::Query::Sequence;
use Krawfish::Koral::Query::Token;
use Krawfish::Koral::Query::Span;
use Krawfish::Koral::Query::Term;
use Krawfish::Koral::Query::TermGroup;
use Krawfish::Koral::Query::Class;
use Krawfish::Koral::Query::Repetition;
use Krawfish::Koral::Query::Length;
use Krawfish::Koral::Query::Exclusion;
use Krawfish::Koral::Query::Constraint;
use Krawfish::Koral::Query::Or;
use Krawfish::Koral::Query::Nowhere;
use Krawfish::Koral::Query::Unique;

use Krawfish::Koral::Query::Constraint::Position;
use Krawfish::Koral::Query::Constraint::ClassBetween;
use Krawfish::Koral::Query::Constraint::NotBetween;
use Krawfish::Koral::Query::Constraint::InBetween;

# TODO:
#   Merge with Builder!

sub new {
  my $var;
  bless \$var, shift;
};

# Deserialization of KoralQuery
# TODO: export this method from Importer


sub from_koral {
  my ($self, $kq) = @_;

  my $type = $kq->{'@type'};
  if ($type eq 'koral:group') {
    my $op = $kq->{operation};
    if ($op eq 'operation:sequence') {
      return $self->seq($kq);
    }

    elsif ($op eq 'operation:class') {
      return $self->class($kq);
    }

    elsif ($op eq 'operation:length') {
      return $self->length($kq);
    }

    elsif ($op eq 'operation:repetition') {
      return $self->repeat($kq);
    }

    elsif ($op eq 'operation:exclusion') {
      return $self->exclusion($kq);
    }

    elsif ($op eq 'operation:position' || $op eq 'operation:constraint') {
      return $self->constraint($kq);
    }

    elsif ($op eq 'operation:disjunction' || $op eq 'operation:or') {
      return $self->bool_or($kq);
    }

    elsif ($op eq 'operation:unique') {
      return $self->unique($kq);
    }

    else {
      warn 'Operation ' . $op . ' no supported';
    };
  }

  elsif ($type eq 'koral:token') {
    return $self->token($kq);
  }

  elsif ($type eq 'koral:span') {
    return $self->span($kq);
  }

  elsif ($type eq 'koral:nowhere') {
    return $self->nowhere;
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
sub from_term_or_term_group {
  my ($self, $kq) = @_;
  my $type = $kq->{'@type'};

  # Defines a term
  if ($type eq 'koral:term') {
    return $self->term($kq);
  }

  # Defines a term group
  elsif ($type eq 'koral:termGroup') {
    return $self->term_group($kq);
  }

  # Matches nowhere
  elsif ($type eq 'koral:nowhere') {
    return $self->nowhere;
  };

  warn 'Not term or termGroup: ' . $kq->{'@type'};

  return;
};


# Import sequence
sub seq {
  shift;
  return Krawfish::Koral::Query::Sequence->from_koral(shift);
};


# Import token
sub token {
  shift;
  return Krawfish::Koral::Query::Token->from_koral(shift);
};


# Import span
sub span {
  shift;
  return Krawfish::Koral::Query::Span->from_koral(shift);
};


# Import term
sub term {
  shift;
  my $kq = shift;

  if (defined $kq->{id}) {
    return Krawfish::Koral::Query::TermID->from_koral($kq);
  };

  return Krawfish::Koral::Query::Term->from_koral($kq);
};


# Import unique
sub unique {
  shift;
  return Krawfish::Koral::Query::Unique->from_koral(shift);
};


# Import term
sub term_group {
  shift;
  return Krawfish::Koral::Query::TermGroup->from_koral(shift);
};


# Import class
sub class {
  shift;
  return Krawfish::Koral::Query::Class->from_koral(shift);
};


# Import position
sub constraint {
  shift;
  return Krawfish::Koral::Query::Constraint->from_koral(shift);
};

sub nowhere {
  return Krawfish::Koral::Query::Nowhere->from_koral();
};

# Import disjunction
sub bool_or {
  shift;
  return Krawfish::Koral::Query::Or->from_koral(shift);
};


# Import exclusion
sub exclusion {
  shift;
  return Krawfish::Koral::Query::Exclusion->from_koral(shift);
};


# Import length
sub length {
  shift;
  return Krawfish::Koral::Query::Length->from_koral(shift);
};


# Import repetition
sub repeat {
  shift;
  return Krawfish::Koral::Query::Repetition->from_koral(shift);
};

1;
