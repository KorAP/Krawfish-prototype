package Krawfish::Koral::Query::Token;
use parent 'Krawfish::Koral::Query';
use Krawfish::Koral::Query::Term;
use strict;
use warnings;

sub new {
  my $class = shift;
  bless {
    term => shift
  }, $class;
};

sub term {
  shift->{term};
};

sub to_koral_fragment {
  my $self = shift;
  if ($self->term) {
    my $koral = Krawfish::Koral::Query::Term->new($self->term) or return {
      '@type' => 'koral:undefined'
    };
    return $koral->to_koral_fragment;
  };
  return {
    '@type' => 'koral:token'
  };
};

sub to_string {
  return '[' . ($_[0]->term // '') . ']';
};

1;
