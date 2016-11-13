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

  bless {
    frames  => _to_frame($frame_array),
    first   => $first,
    second  => $second,
    info => undef
  }, $class;
};

# Return KoralQuery fragment
sub to_koral_fragment {
  my $self = shift;
  my $koral = {
    '@type' => 'koral:group',
    'operation' => 'operation:position',
    'exclude' => Mojo::JSON->true,
    'frames' => [map { 'frames:' . $_ } _to_list($self->{frames})],
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
#  my ($self, $index) = @_;
#  my $frames = $self->{frames};
#  my $first = $self->{first};
#  my $second = $self->{second};
  ...
};


sub to_string {
  my $self = shift;
  my $string = 'excl(';
  $string .= (0 + $self->{frames}) . ':';
  $string .= $self->{first}->to_string . ',';
  $string .= $self->{second}->to_string;
  return $string . ')';
};

# Return if the query may result in an 'any' left extension
# [][Der]
sub is_extended_left {
  ...
};


# Return if the query may result in an 'any' right extension
# [Der][]
sub is_extended_right {
  ...
};


# return if the query is extended either to the left or to the right
sub is_extended {
  ...
};


1;


__END__

