package Krawfish::Koral::Query::Position;
use parent 'Krawfish::Koral::Query';
use strict;
use warnings;

sub new {
  my $class = shift;
  bless {
    exclude => shift,
    frames => shift,
    first => shift,
    second => shift
  }, $class;
};

# Return KoralQuery fragment
sub to_koral_fragment {
  my $self = shift;
  return {
    '@type' => 'koral:group',
    'operation' => 'operation:position',
    'frames' => [map { 'frames:' . $_ } _to_list($self->{frames})],
    'operands' => [
      $self->{first}->to_koral_query_fragment,
      $self->{second}->to_koral_query_fragment
    ]
  };
};

sub _to_list {
...
};

1;
