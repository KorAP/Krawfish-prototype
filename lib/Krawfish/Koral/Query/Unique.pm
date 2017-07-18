package Krawfish::Koral::Query::Unique;
use parent 'Krawfish::Koral::Query';
use Krawfish::Query::Unique;
use strict;
use warnings;

sub new {
  my $class = shift;
  bless {
    span => shift
  }
};

sub to_koral_fragment {
  ...
};

sub type { 'unique' };


sub normalize {
  my $self = shift;

  my $span;
  unless ($span = $self->span->normalize) {
    $self->copy_info_from($self->span);
    return;
  };

  $self->{span} = $span;

  return $self;
};


sub optimize {
  my ($self, $index) = @_;

  my $span = $self->span->optimize($index) or return;

  if ($span->freq == 0) {
    return $self->builder->nothing;
  };

  return Krawfish::Query::Unique->new($span);
};


# Filter by corpus
sub filter_by {
  my $self = shift;
  $self->{span}->filter_by(shift);
};


sub to_string {
  my $self = shift;
  return 'unique(' . $self->span->to_string . ')';
};

sub span {
  $_[0]->{span};
};

# TODO: Identical to class

sub is_any {
  $_[0]->span->is_any;
};

sub is_optional {
  $_[0]->span->is_optional;
};

sub is_null {
  $_[0]->span->is_null;
};

sub is_negative {
  $_[0]->span->is_negative;
};

sub is_extended {
  $_[0]->span->is_extended;
};

sub is_extended_right {
  $_[0]->span->is_extended_right;
};

sub is_extended_left {
  $_[0]->span->is_extended_left;
};

sub is_classed {
  $_[0]->span->is_classed;
};

sub maybe_unsorted {
  $_[0]->span->maybe_unsorted;
};

1;
