package Krawfish::Koral::Query::Exclusion;
use strict;
use warnings;
use Role::Tiny::With;
# Exports to_frame:
use Krawfish::Koral::Query::Constraint::Position;
use Krawfish::Query::Exclusion;
use Krawfish::Log;
use Mojo::JSON;
use Memoize;
memoize('min_span');
memoize('max_span');

with 'Krawfish::Koral::Query';

use constant DEBUG => 0;

# TODO:
#   Take care of punctuations in (as they have different
#   position information) -> excl(succedsDirectly:[corenlp/p=N],[.])


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
    'operation' => 'operation:exclusion',
    'frames' => [map { 'frames:' . $_ } to_list($self->{frames})],
    'operands' => [
      $self->operands->[0]->to_koral_fragment,
      $self->operands->[1]->to_koral_fragment
    ]
  };
  return $koral;
};


# Deserialize from KoralQuery
sub from_koral {
  my ($class, $kq) = @_;
  my $qb = $class->builder;
  my @frames = ();

  # Set default frames
  unless ($kq->{frames}) {
    push @frames,
      ('frames:isAround',
       'frames:endsWith',
       'frames:startsWith',
       'frames:matches');
  }
  else {
    @frames = @{$kq->{frames}};
  };

  my $op1 = $qb->from_koral($kq->{operands}->[0]);
  my $op2 = $qb->from_koral($kq->{operands}->[1]);

  $class->new(\@frames, $op1, $op2);
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

  # There is nowhere to exclude
  if ($second->is_nowhere) {

    if (DEBUG) {
      print_log('kq_excl', 'Second operand matches nowhere: ' . $second->to_string);
    };

    # Match complete $first
    return $first;
  };


  my ($first_norm, $second_norm);
  if ($first->is_anywhere) {

    # Negation with [] may occur with boolean operations
    $second->warning(
      782,
      'Exclusivity of query is ignored',
      $second->to_string
    );

    # Query normalization
    unless ($second_norm = $second->normalize) {
      $self->copy_info_from($second);
      return;
    };

    return $second_norm;
  };

  # Todo:
  #   Find a common way to do this
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

    return $self->builder->nowhere->normalize;
  };

  $self->operands([
    $first_norm,

    # Remove unused classes, as they can't match
    $second_norm->remove_unused_classes
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

  if ($ops->[0]->is_nowhere) {
    return $self->builder->nowhere;
  };

  $ops->[1] = $ops->[1]->identify($dict);

  if ($ops->[1]->is_nowhere) {
    return $ops->[0];
  };

  return $self;
};


sub optimize {
  my ($self, $segment) = @_;

  print_log('kq_excl', 'Optimize exclusion') if DEBUG;

  my $frames = $self->{frames};

  my $ops = $self->operands;

  my $first = $ops->[0]->optimize($segment);
  my $second = $ops->[1]->optimize($segment);

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
  my ($self, $id) = @_;
  my $string = 'excl(';
  $string .= join(';', to_list($self->{frames})) . ':';
  # $string .= (0 + $self->{frames}) . ':';
  $string .= $self->operands->[0]->to_string($id) . ',';
  $string .= $self->operands->[1]->to_string($id);
  return $string . ')';
};


sub is_anywhere {
  $_[0]->operands->[0]->is_anywhere;
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


# Return if the query may result in an 'anywhere' left extension
sub is_extended_left {
  return $_[0]->operands->[0]->is_extended_left;
};


# Return if the query may result in an 'anywhere' right extension
sub is_extended_right {
  return $_[0]->operands->[0]->is_extended_right;
};


1;


__END__

