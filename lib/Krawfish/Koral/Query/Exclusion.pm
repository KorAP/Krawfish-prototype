package Krawfish::Koral::Query::Exclusion;
use parent 'Krawfish::Koral::Query';
# Exports to_frame:
use Krawfish::Koral::Query::Constraint::Position;
use Krawfish::Query::Exclusion;
use Krawfish::Log;
use Mojo::JSON;
use strict;
use warnings;
use Memoize;
memoize('min_span');
memoize('max_span');

use constant DEBUG => 1;

sub new {
  my $class = shift;
  my ($frame_array, $first, $second) = @_;

  my $self = bless {
    operands => [$first, $second]
  }, $class;

  $self->{frames}  = to_frame(@$frame_array);
  return $self;
};


# Return KoralQuery fragment
sub to_koral_fragment {
  my $self = shift;
  my $koral = {
    '@type' => 'koral:group',
    'operation' => 'operation:position',
    'exclude' => Mojo::JSON->true,
    'frames' => [map { 'frames:' . $_ } $self->_to_list($self->{frames})],
    'operands' => [
      $self->operands->[0]->to_koral_query_fragment,
      $self->operands->[1]->to_koral_query_fragment
    ]
  };
  return $koral;
};


#########################################
# Query Planning methods and attributes #
#########################################

sub type { 'exclusion' };


sub normalize {
  my $self = shift;

  print_log('kq_excl', 'Normalize exclusion') if DEBUG;

  my $frames = $self->{frames};
  my $first = $self->operands->[0];
  my $second = $self->operands->[1];

  # There is nothing to exclude
  if ($second->is_nothing) {

    if (DEBUG) {
      print_log('kq_excl', 'Second operand matches nowhere: ' . $second->to_string);
    };

    # Match complete $first
    return $first;
  };

  # Todo:
  #   Find a common way to do this
  my ($first_norm, $second_norm);
  unless ($first_norm = $first->normalize) {
    $self->copy_info_from($first);
    return;
  };

  unless ($second_norm = $second->normalize) {
    $self->copy_info_from($second);
    return;
  };

  # Normalize contradiction
  if ($self->{frames} == MATCHES &&
        $first_norm->to_string eq $second_norm->to_string) {

    if (DEBUG) {
      print_log('kq_excl', 'First and second operand are equal');
    };

    return $self->builder->nothing->normalize;
  };

  $self->operands([
    $first_norm,

    # Remove all classes, as they can't match
    $second_norm->remove_classes
  ]);

  return $self;
};


# An exclusion always spans its first operand span
sub min_span {
  $_[0]->operands->[0]->min_span;
};


# An exclusion always spans its first operand span
sub max_span {
  $_[0]->operands->[0]->max_span;
};



sub identify {
  my ($self, $dict) = @_;

  print_log('kq_excl', 'Identify exclusion') if DEBUG;

  my $ops = $self->operands;
  $ops->[0] = $ops->[0]->identify($dict);

  if ($ops->[0]->is_nothing) {
    return $self->builder->nothing;
  };

  $ops->[1] = $ops->[1]->identify($dict);

  if ($ops->[1]->is_nothing) {
    return $ops->[0];
  };

  return $self;
};


sub optimize {
  my ($self, $index) = @_;

  print_log('kq_excl', 'Optimize exclusion') if DEBUG;

  my $frames = $self->{frames};
  my $first = $self->operands->[0]->optimize($index);
  my $second = $self->operands->[1]->optimize($index);

  # Second object does not occur
  if ($second->max_freq == 0) {
    return $first;
  };

  return Krawfish::Query::Exclusion->new(
    $self->{frames},
    $first,
    $second
  );
};



sub to_string {
  my $self = shift;
  my $string = 'excl(';
  $string .= (0 + $self->{frames}) . ':';
  $string .= $self->operands->[0]->to_string . ',';
  $string .= $self->operands->[1]->to_string;
  return $string . ')';
};


sub is_any {
  $_[0]->operands->[0]->is_any;
};


sub is_optional {
  $_[0]->operands->[0]->is_optional;
};

sub is_null {
  $_[0]->operands->[0]->is_null;
};

sub is_negative {
  $_[0]->operands->[0]->is_negative;
};

sub maybe_unsorted {
  $_[0]->operands->[0]->maybe_unsorted;
};


# Return if the query may result in an 'any' left extension
sub is_extended_left {
  return $_[0]->operands->[0]->is_extended_left;
};


# Return if the query may result in an 'any' right extension
sub is_extended_right {
  return $_[0]->operands->[0]->is_extended_right;
};


1;


__END__

