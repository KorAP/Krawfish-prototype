package Krawfish::Query::Constraints;
use parent 'Krawfish::Query';
use Krawfish::Log;
use strict;
use warnings;

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

# Initialize both spans
sub init {
  return if $_[0]->{init}++;
  print_log('constr', 'Init dual spans') if DEBUG;
  $_[0]->{first}->next;
  $_[0]->{second}->next;
  $_[0]->{buffer}->remember($_[0]->{second}->current);
};

sub constraint_check {
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

  return $ret_val | MATCH;
};


sub next {
  my $self = shift;
  $self->init;

  my ($first, $second);
  my $payload = Krawfish::Posting::Payload->new;

  while (1) {
    unless ($first = $self->{first}->current) {
      print_log('constr', 'No more first items, return false 1') if DEBUG;
      $self->{doc_id} = undef;
      return;
    };

    unless ($second = $self->{buffer}->current) {
      print_log('constr', 'Buffer is empty') if DEBUG;

      # Forward span
      unless ($self->{first}->next) {
        # May point to no current
        print_log('dual', 'Return false 2') if DEBUG;
        $self->{doc_id} = undef;
        return;
      };

      # Reset buffer
      $self->{buffer}->to_start;
      next;
    };

    # TODO: Check if second may not be at the end
    # of the buffer

    # Equal documents - check!
    if ($first->doc_id == $second->doc_id) {
      print_log('constr', 'Documents are equal - check the configuration') if DEBUG;
      print_log('constr', "Configuration is $first vs $second") if DEBUG;

      # Check configuration
      my $check = $self->constraint_check($payload, $first, $second);

      print_log('constr', 'Plan next step based on ' . (0 + $check)) if DEBUG;

      # next b is possible
      if ($check & NEXTB) {

        # Only next b is possible
        if (!($check & NEXTA)) {

          print_log('constr', 'Only next B is possible') if DEBUG;

          # Forget the current buffer
          $self->{buffer}->forget;
        };

        # Forward buffer - or span
        if (!($self->{buffer}->next)) {
          # This will never be true

          print_log('constr', 'Unable to forward buffer - get next') if DEBUG;

          if ($self->{second}->next) {
            $self->{buffer}->remember(
              $self->{second}->current
            );

            # Position finger to last item
            $self->{buffer}->to_end;
          }
          else {
            $self->{buffer}->forward;
          };
        };
      }

      # Only next a is possible
      elsif ($check & NEXTA) {

        print_log('constr', 'Only next A is possible') if DEBUG;

        # Forward span
        $self->{first}->next;
        # May point to no current

        # Reset buffer
        $self->{buffer}->to_start;
      }

      # Can never match
      elsif ($check == 0b0000) {
        print_log('constr', 'Can never match') if DEBUG;
      };

      # The configuration matches
      if ($check & MATCH) {

        # Set current
        $self->{doc_id} = $first->doc_id;
        $self->{start} = $first->start < $second->start ? $first->start : $second->start;
        $self->{end}   = $first->end > $second->end ? $first->end : $second->end;
        $self->{payload} = $first->payload->clone->copy_from($second->payload)->copy_from($payload);
        print_log('constr', "There is a match - make current match: " . $self->current) if DEBUG;

        print_log('constr', 'MATCH!') if DEBUG;
        return 1 ;
      };
    }

    # The first span is behind
    elsif ($first->doc_id < $second->doc_id) {

      # TODO: This may be wrong, because there may be
      # a second candidate in the same document
      $self->{buffer}->clear;
      unless ($self->{first}->next) {
        $self->{doc_id} = undef;
        return;
      };
    }

    # The second span is behind
    else {
      $self->{buffer}->clear;
      unless ($self->{second}->next) {
        $self->{doc_id} = undef;
        return;
      };
    };
  };

  return;
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
