package Krawfish::Koral::Query::Importer;
use warnings;
use strict;
use Krawfish::Koral::Query;
use Krawfish::Koral::Query::Sequence;
use Krawfish::Koral::Query::Token;
use Krawfish::Koral::Query::Span;
use Krawfish::Koral::Query::Term;
use Krawfish::Koral::Query::Class;
use Krawfish::Koral::Query::Repetition;
use Krawfish::Koral::Query::Length;

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

  else {
    warn $type . ' unknown';
  };

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
  return Krawfish::Koral::Query::Term->from_koral(shift);
};


# Import class
sub class {
  shift;
  return Krawfish::Koral::Query::Class->from_koral(shift);
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
