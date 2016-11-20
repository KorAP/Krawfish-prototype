package Krawfish::Koral::Query::Exclusion;
use parent 'Krawfish::Koral::Query::Position';
use Krawfish::Query::Position;
use Krawfish::Query::Exclusion;
use Mojo::JSON;
use strict;
use warnings;

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

sub plan_for {
  my ($self, $index) = @_;
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

  return Krawfish::Query::Exclusion->new(
    $self->{frames},
    $first_plan,
    $second_plan
  );
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

