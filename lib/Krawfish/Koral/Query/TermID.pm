package Krawfish::Koral::Query::TermID;
use Role::Tiny::With;
use Krawfish::Query::TermID;
use strict;
use warnings;

with 'Krawfish::Koral::Query';

sub new {
  my ($class, $term_id) = @_;
  bless {
    term_id => $term_id
  }, $class;
};

sub type {
  'termid';
};

sub is_leaf {
  1;
};

sub is_nowhere {
  0;
};

sub operands {
  [];
};

sub remove_classes {
  warn 'not available';
};

sub min_span {
  warn 'not available';
};

sub max_span {
  warn 'not available';
};

sub term_id {
  $_[0]->{term_id};
};

sub normalize {
  $_[0];
};

sub optimize {
  my ($self, $segment) = @_;
  return Krawfish::Query::TermID->new($segment, $self->term_id);
};

sub is_anywhere {
  0;
};

sub is_optional {
  0;
};

sub is_null {
  0;
};

sub is_negative {
  0;
};


sub is_extended { 0 };
sub is_extended_right { 0 };
sub is_extended_left { 0 };
sub maybe_unsorted { 0 };


# Stringification
sub to_string {
  return '#' . $_[0]->{term_id};
};


# Serialization
sub to_koral_fragment {
  return {
    '@type' => 'koral:term',
    'id' => shift->term_id
  };
};


# Deserialization
sub from_koral {
  my ($class, $kq) = @_;
  my $id = $kq->{id};
  return $class->new($id);
};


1;


__END__
