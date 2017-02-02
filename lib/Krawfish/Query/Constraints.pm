package Krawfish::Query::Constraints;
use parent 'Krawfish::Query::Base::Dual';
use Krawfish::Log;
use strict;
use warnings;

# TODO:
#   Payload may not be needed to send to check. Always add
#   to first operand payload and then merge!

use constant {
  NEXTA => 1,
  NEXTB => 2,
  MATCH => 4,
  DEBUG => 0
};

# TODO: Improve by skipping to the same document

sub new {
  my $class = shift;
  bless {
    constraints => shift,
    first => shift,
    second => shift,
    buffer  => Krawfish::Query::Util::Buffer->new
  }, $class;
};


sub check {
  my $self = shift;
  my ($payload, $first, $second) = @_;

  # Initialize the return value
  my $ret_val = 0b0111;

  # Iterate
  foreach (@{$self->{constraints}}) {

    # Check constrained
    my $check = $_->check($payload, $first, $second);

    # Combine NEXTA and NEXTB rules
    $ret_val &= $check;

    # Check matches
    unless ($check & MATCH) {

      # No match - send NEXTA and NEXTB rules
      return $ret_val;
    };
  };

  # Match!
  $self->{doc_id} = $first->doc_id;
  $self->{start} = $first->start < $second->start ? $first->start : $second->start;
  $self->{end}   = $first->end > $second->end ? $first->end : $second->end;
  $self->{payload} = $first->payload->clone->copy_from($second->payload);

  return $ret_val | MATCH;
};


sub to_string {
  my $self = shift;
  my $str = 'constr(';
  $str .= join(',', map { $_->to_string } @{$self->{constraints}});
  $str .= ':';
  $str .= $self->{first}->to_string . ',' . $self->{second}->to_string;
  return $str . ')';
};


1;
