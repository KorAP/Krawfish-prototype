package Krawfish::Koral::Query::Importer;
use Krawfish::Koral::Query;
use Krawfish::Koral::Query::Sequence;
use Krawfish::Koral::Query::Token;
use Krawfish::Koral::Query::Term;
use Krawfish::Koral::Query::Class;
use warnings;
use strict;

sub new {
  my $var;
  bless \$var, shift;
};

sub all {
  shift;
  return Krawfish::Koral::Query->from_koral(shift);
};

sub seq {
  shift;
  return Krawfish::Koral::Query::Sequence->from_koral(shift);
};

sub token {
  shift;
  return Krawfish::Koral::Query::Token->from_koral(shift);
}

sub term {
  shift;
  return Krawfish::Koral::Query::Term->from_koral(shift);
};


sub class {
  shift;
  return Krawfish::Koral::Query::Class->from_koral(shift);
}

1;
