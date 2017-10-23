package Krawfish::Koral::Corpus::Class;
use parent 'Krawfish::Koral::Corpus';
use Krawfish::Log;
use strict;
use warnings;
use constant DEBUG => 0;


sub new {
  my $class = shift;
  bless {
    number => shift,
    operands => [shift]
  }, $class;
};


sub type {
  'class';
};


sub number {
  $_[0]->{number};
};


sub is_negative {
  $_[0]->operand->is_negative;
};


sub has_classes {
  1;
};

sub normalize {
  my $self = shift;
  $self->operand($self->operand->normalize);
  $self;
};


# Optimize query
sub optimize {
  my ($self, $segment) = @_;

  # Plan corpus
  my $corpus = $self->operand->optimize($segment);

  # Create class query
  return Krawfish::Corpus::Class->new(
    $corpus,
    $self->number
  );
};


sub to_koral_fragment {
  my $self = shift;
  return {
    '@type' => 'koral:fieldGroup',
    'operation' => 'operation:class',
    'classOut' => $self->number,
    'operands' => [
      $self->operand->to_koral_fragment
    ]
  };
};


sub to_string {
  my $self = shift;
  my $str = '{' . $self->number . ':';
  $str . $self->operand->to_string . '}';
};

1;
