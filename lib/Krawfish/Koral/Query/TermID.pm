package Krawfish::Koral::Query::TermID;
use parent 'Krawfish::Koral::Query';
use Krawfish::Query::TermID;
use strict;
use warnings;

sub new {
  my ($class, $term_id) = @_;
  bless \$term_id, $class;
};

sub type {
  'termid';
};

sub is_leaf {
  1;
};

sub is_nothing {
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

sub to_koral_fragment {
  ...
};

sub to_string {
  return ${$_[0]};
};

sub optimize {
  my ($self, $index) = @_;
  return Krawfish::Query::TermID->new($index, $$self);
};

sub is_any {
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

sub from_koral {
  ...
};

1;

__END__
