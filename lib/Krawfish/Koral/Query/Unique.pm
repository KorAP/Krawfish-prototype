package Krawfish::Koral::Query::Unique;
use Role::Tiny::With;
use Krawfish::Query::Unique;
use strict;
use warnings;

with 'Krawfish::Koral::Query::Proxy';
with 'Krawfish::Koral::Query';

sub new {
  my $class = shift;
  bless {
    operands => [shift]
  }
};


sub type {
  'unique'
};


# Normalize unique query
sub normalize {
  my $self = shift;

  my $span;
  unless ($span = $self->operand->normalize) {
    $self->copy_info_from($self->operand);
    return;
  };

  $self->operands([$span]);

  return $self;
};


# Optimize unique query
sub optimize {
  my ($self, $segment) = @_;

  my $span = $self->operand->optimize($segment) or return;

  if ($span->max_freq == 0) {
    return $self->builder->nowhere;
  };

  return Krawfish::Query::Unique->new($span);
};


# Stringification
sub to_string {
  my ($self, $id) = @_;
  return 'unique(' . $self->operand->to_string($id) . ')';
};


# serialize
sub to_koral_fragment {
  my $self = shift;
  return {
    '@type' => 'koral:group',
    'operation' => 'operation:unique',
    'operands' => [
      $self->operand->to_koral_fragment
    ]
  };
};


# Deserialize
sub from_koral {
  my ($class, $kq) = @_;
  my $op = $kq->{operands}->[0];
  return $class->new(
    $class->builder->from_koral($op)
  );
};


1;
