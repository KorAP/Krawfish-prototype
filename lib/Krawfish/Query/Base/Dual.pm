package Krawfish::Query::Base::Dual;
use parent 'Exporter', 'Krawfish::Query';
use strict;
use warnings;
use Krawfish::Log;
use Krawfish::Query::Util::Buffer;
use Krawfish::Posting;

our @EXPORT;

use constant {
  NEXTA  => 1,
  NEXTB  => 2,
  MATCH  => 4,
  DEBUG  => 0
};

@EXPORT = qw/NEXTA NEXTB MATCH/;

# TODO: Next to NEXTA and NEXTB there should be flags for:
#       NEXTX to STARTY   (Position skipping)
#       NEXTX to ENDY     (Position skipping)
#       NEXTX to ENDX     (Position skipping)
#       NEXTX to STARTX+1 (Position skipping)

# TODO: Improve by skipping to the same document

sub new {
  my $class = shift;
  bless {
    first => shift,
    second => shift,
    buffer  => Krawfish::Query::Util::Buffer->new
  }, $class;
};


# Initialize both spans
sub init {
  return if $_[0]->{init}++;
  print_log('dual', 'Init dual spans') if DEBUG;
  $_[0]->{first}->next;
  $_[0]->{second}->next;
  $_[0]->{buffer}->remember($_[0]->{second}->current);
};


# This will advance the two spans
sub next {
  my $self = shift;
  $self->init;

  my ($first, $second);

  while (1) {
    unless ($first = $self->{first}->current) {
      print_log('dual', 'No more first items, return false 1') if DEBUG;

      $self->{doc_id} = undef;
      return;
    };

    unless ($second = $self->{buffer}->current) {
      print_log('dual', 'Buffer is empty') if DEBUG;

      # Check configuration
      my $check = $self->check($first, undef);

      print_log('dual', 'Final check is '. (0+$check)) if DEBUG;

      # Expect a next_a
      if ($check & NEXTA) {

        # Forward span
        $self->{first}->next;
      };

      # The configuration matches
      if ($check & MATCH) {
        print_log('dual', 'MATCH!') if DEBUG;
        return 1 ;
      };

      # Reset buffer
      $self->{buffer}->to_start;
      $self->{doc_id} = undef;
      return;
      # next;
    };

    # TODO: Check if second may not be at the end
    # of the buffer

    # Equal documents - check!
    if ($first->doc_id == $second->doc_id) {
      print_log('dual', 'Documents are equal - check the configuration') if DEBUG;
      print_log('dual', "Configuration is $first vs $second") if DEBUG;

      # Check configuration
      my $check = $self->check($first, $second);

      print_log('dual', 'Next step after check returned ' . (0 + $check)) if DEBUG;

      # next b is possible
      if ($check & NEXTB) {

        # Only next b is possible
        if (!($check & NEXTA)) {

          print_log('dual', 'Only next B is possible') if DEBUG;

          # Forget the current buffer
          $self->{buffer}->forget;
        }
        elsif (DEBUG) {
          print_log('dual', 'Next A and next B is possible') if DEBUG;
        };

        # Forward buffer - or span
        if (!($self->{buffer}->next)) {
          # This will never be true

          print_log('dual', 'Unable to forward buffer - get next posting') if DEBUG;

          # Check next posting
          if ($self->{second}->next) {
            $self->{buffer}->remember(
              $self->{second}->current
            );

            # Position finger to last item
            $self->{buffer}->to_end;
          }

          # Check if nextA is supported
          elsif ($check & NEXTA) {
            print_log('dual', 'Second has no further postings') if DEBUG;

            # Check configuration
            my $check = $self->check($first, undef);

            $self->{first}->next;
            $self->{buffer}->to_start;

            if ($check & MATCH) {
              return 1;
            };
          }

          # No, nothing
          else {
            print_log('dual', 'There is no next second') if DEBUG;

            # May be wrong (untested!)
            $self->{buffer}->forward;
          };
        };
      }

      # Only next a is possible
      elsif ($check & NEXTA) {

        print_log('dual', 'Only next A is possible') if DEBUG;

        # Forward span
        $self->{first}->next;
        # May point to no current

        # Reset buffer
        $self->{buffer}->to_start;
      }

      # No forwarding
      else {
        $self->{buffer}->clear;
        $self->{doc_id} = undef;
        return;
      };

      # The configuration matches
      if ($check & MATCH) {
        print_log('dual', 'MATCH!') if DEBUG;
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


1;

__END__
