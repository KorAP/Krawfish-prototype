package Krawfish::Query::Constraints;
use parent 'Krawfish::Query::Base::Dual';
use Krawfish::Log;
use strict;
use warnings;

use constant {
  NEXTA => 1,
  NEXTB => 2,
  MATCH => 4,
  DEBUG => 1
};

# TODO: Improve by skipping to the same document

sub new {
  my $class = shift;
  bless {
    constraints => shift,
    first => shift,
    second => shift,

    # TODO:
    #   Second operand should be nested in buffer by Dual
    buffer  => Krawfish::Query::Util::Buffer->new
  }, $class;
};


# Check all constraints sequentially
sub check {
  my $self = shift;
  my ($first, $second) = @_;

  # Initialize the return value
  my $ret_val = 0b0111;

  # Iterate
  foreach (@{$self->{constraints}}) {

    # TODO:
    #   Under certain circumstances it may be
    #   faster to 

    # Check constrained
    my $check = $_->check($first, $second);

    # Combine NEXTA and NEXTB rules
    $ret_val &= $check;

    # Check matches
    unless ($check & MATCH) {

      # No match - send NEXTA and NEXTB rules
      return $ret_val;
    };
  };

  # Match!
  $self->{doc_id}  = $first->doc_id;
  $self->{start}   = $first->start < $second->start ? $first->start : $second->start;
  $self->{end}     = $first->end > $second->end ? $first->end : $second->end;
  $self->{payload} = $first->payload->clone->copy_from($second->payload);

  print_log('constr', 'Constraint matches: ' . $self->current->to_string) if DEBUG;

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
