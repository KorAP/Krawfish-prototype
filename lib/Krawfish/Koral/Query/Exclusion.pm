package Krawfish::Koral::Query::Exclusion;
use parent 'Krawfish::Koral::Query::Position';
use Krawfish::Query::Exclusion;
use Krawfish::Log;
use Mojo::JSON;
use strict;
use warnings;

use constant DEBUG => 1;

sub new {
  my $class = shift;
  my ($frame_array, $first, $second) = @_;

  my $self = bless {
    first   => $first,
    second  => $second
  }, $class;

  $self->{frames}  = $self->_to_frame($frame_array);
  return $self;
};


# Remove classes passed as an array references
sub remove_classes {
  my ($self, $keep) = @_;
  unless ($keep) {
    $keep = [];
  };
  $self->{first} = $self->{first}->remove_classes($keep);
  $self->{second} = $self->{second}->remove_classes($keep);
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
      $self->{first}->to_koral_query_fragment,
      $self->{second}->to_koral_query_fragment
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
  my $first = $self->{first};
  my $second = $self->{second};

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

  $self->{first} = $first_norm;

  # Remove all classes, as they can't match
  $self->{second} = $second_norm->remove_classes;

  # Normalize!
  if ($self->{first}->to_string eq $self->{second}->to_string) {

    if (DEBUG) {
      print_log('kq_excl', 'First and second operand are equal');
    };

    return $self->builder->nothing->normalize;
  };

  return $self;
};


sub inflate {
  my ($self, $dict) = @_;

  print_log('kq_excl', 'Inflate exclusion') if DEBUG;

  $self->{first} = $self->{first}->inflate($dict);
  $self->{second} = $self->{second}->inflate($dict);
  return $self;
};

sub optimize {
  my ($self, $index) = @_;

  print_log('kq_excl', 'Optimize exclusion') if DEBUG;

  my $frames = $self->{frames};
  my $first = $self->{first}->optimize($index);
  my $second = $self->{second}->optimize($index);

  # Second object does not occur
  if ($second->freq == 0) {
    return $first;
  };

  return Krawfish::Query::Exclusion->new(
    $self->{frames},
    $first,
    $second
  );
};

sub plan_for {
  my ($self, $index) = @_;

  warn 'DEPRECATED';

  my $frames = $self->{frames};
  my $first = $self->{first};
  my $second = $self->{second};

  my ($first_plan, $second_plan);
  unless ($first_plan = $self->{first}->plan_for($index)) {
    $self->copy_info_from($self->{first});
    return;
  };

  unless ($second_plan = $self->{second}->plan_for($index)) {
    $self->copy_info_from($self->{second});
    return;
  };

  # Second object does not occur
  if ($second_plan->freq == 0) {
    return $first_plan;
  };

  return Krawfish::Query::Exclusion->new(
    $self->{frames},
    $first_plan,
    $second_plan
  );
};

sub filter_by {
  my $self = shift;
  $self->{first}->filter_by(shift);
};


sub to_string {
  my $self = shift;
  my $string = 'excl(';
  $string .= (0 + $self->{frames}) . ':';
  $string .= $self->{first}->to_string . ',';
  $string .= $self->{second}->to_string;
  return $string . ')';
};


sub is_any {
  $_[0]->{first}->is_any;
};


sub is_optional {
  $_[0]->{first}->is_optional;
};

sub is_null {
  $_[0]->{first}->is_null;
};

sub is_negative {
  $_[0]->{first}->is_null;
};

sub maybe_unsorded {
  $_[0]->{first}->maybe_unsorted;
};


# Return if the query may result in an 'any' left extension
sub is_extended_left {
  return $_[0]->{first}->is_extended_left;
};


# Return if the query may result in an 'any' right extension
sub is_extended_right {
  return $_[0]->{first}->is_extended_right;
};


1;


__END__

