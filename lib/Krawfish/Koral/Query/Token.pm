package Krawfish::Koral::Query::Token;
use parent 'Krawfish::Koral::Query';
use Krawfish::Koral::Query::Token;
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


# Overwrite is any
sub is_any {
  return 1 unless $_[0]->term;
  return;
};

sub plan_for {
  my ($self, $index) = @_;
  return unless $self->term;
  return Krawfish::Query::Token->new(
    $index,
    $self->term
  );
};

sub to_string {
  my $string = '[' . ($_[0]->term // '') . ']';
  if ($_[0]->is_null) {
    $string .= '{0}';
  }
  elsif ($_[0]->is_optional) {
    $string .= '?';
  };
  return $string;
};

1;
