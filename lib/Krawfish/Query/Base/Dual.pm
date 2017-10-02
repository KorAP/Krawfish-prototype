package Krawfish::Query::Base::Dual;
use parent 'Exporter', 'Krawfish::Query';
use strict;
use warnings;
use Krawfish::Log;
use Krawfish::Util::Buffer;
use Krawfish::Posting;
use bytes;

our @EXPORT;

# TODO:
#   Wrap second query in a buffered query instead of
#   dealing with buffer resizing etc. here!

# TODO:
#   Improve by skipping to the same document
#   (not for exclusion!)

# TODO:
#   Possibly do NOT buffer every match - that's especially
#   costly for skipping and in case the posting is already
#   either buffered (part of a nested query) or lifted
#   (part of a postings list)

use constant {
  NEXTA  => 1,
  NEXTB  => 2,
  MATCH  => 4,
  DEBUG  => 0
};

@EXPORT = qw/NEXTA NEXTB MATCH/;

sub new {
  my $class = shift;
  bless {
    first => shift,
    second => shift,
    buffer  => Krawfish::Util::Buffer->new
  }, $class;
};


# Initialize both spans
sub init {
  return if $_[0]->{init}++;
  if (DEBUG) {
    print_log('dual', 'Init dual spans: ' . $_[0]->{first}->to_string . ' and ' .
                $_[0]->{second}->to_string);
  };
  $_[0]->{first}->next;
  $_[0]->{second}->next;
  $_[0]->{buffer}->remember($_[0]->{second}->current);
};


# This will advance the two spans
sub next {
  my $self = shift;
  $self->init;

  my ($first, $second);

  # This is an infinite loop
  while (1) {

    # Stop if there is no first span
    unless ($first = $self->{first}->current) {
      print_log('dual', 'No more first items, return false 1') if DEBUG;
      $self->{doc_id} = undef;
      return;
    };


    # Check if there is no second span in buffer
    unless ($second = $self->{buffer}->current) {
      print_log('dual', 'Buffer has no current element') if DEBUG;

      # Check configuration, because in the case of exclusion,
      # a match may be valid even if no second operand exists
      my $check = $self->check($first, undef);

      print_log('dual', 'Final check is '. (0+$check)) if DEBUG;

      # The configuration has a match
      if ($check & MATCH) {

        # The configuration accepts forwarding A
        if ($check & NEXTA) {

          # Forward span
          print_log('dual', 'Forward A') if DEBUG;
          $self->{first}->next;

          # Reset buffer
          # TODO: Check if this is necessary
          $self->{buffer}->rewind;
        };

        if (DEBUG) {
          print_log('dual', "! MATCH: $first vs " . ($second ? $second : 'NULL') . '!');
        };

        # Configuration matches, even without a second operand
        return 1;
      };

      # Fail
      $self->{doc_id} = undef;
      return;
    };


    # There is a first and a second operand


    # TODO:
    #   Check if second may not be at the end
    #   of the buffer


    # Both elements are in the same document
    if ($first->doc_id == $second->doc_id) {

      if (DEBUG) {
        print_log('dual', 'Documents are equal - check the configuration');
        print_log('dual', "Configuration is $first vs $second");
      };

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
          print_log('dual', 'Next A and next B is possible');
        };

        # Forward buffer - or span
        if (!($self->{buffer}->next)) {

          print_log('dual', 'Unable to forward buffer - get next posting') if DEBUG;

          # Check next posting
          if ($self->{second}->next) {

            print_log('dual', 'Try to forward B') if DEBUG;

            $self->{buffer}->remember(
              $self->{second}->current
            );

            # Position finger to last item
            $self->{buffer}->to_end;
          }

          # Check if nextA is supported
          elsif ($check & NEXTA) {

            print_log('dual', 'B has no further postings') if DEBUG;

            # Check if the current match was
            # already matched
            unless ($check & MATCH) {

              print_log('dual', 'Check is no match') if DEBUG;
              # No it wasn't

              # If not - check configuration would
              # be valid even without a partner span
              my $check = $self->check($first, undef);

              print_log('dual', 'Forward A (1)') if DEBUG;
              $self->{first}->next;
              $self->{buffer}->rewind;

              if ($check & MATCH) {

                if (DEBUG) {
                  print_log('dual', "! MATCH: $first vs NULL!");
                };
                return 1;
              };
            }

            # Current is a match
            else {

              if (DEBUG) {
                print_log('dual', "! MATCH: $first vs $second!");

                # Match was already matched
                print_log('dual', 'Forward A (2)');
              };

              $self->{first}->next;
              $self->{buffer}->rewind;
              return 1;
            };

            # TODO: Next should be default here
            CORE::next;
          }

          # No, nowhere
          else {
            print_log('dual', 'There is no next B') if DEBUG;

            # May be wrong (untested!)
            $self->{buffer}->next;
          };
        }

        # Buffer successfully forwarded
        elsif (DEBUG) {
          print_log('dual', 'Buffer was forwarded') if DEBUG;

          # TODO:
          #   There should be a check that old buffered B can't be possible
          #   in the future so the old buffer entry can be forgotten.
        };
      }

      # Only next a is possible
      elsif ($check & NEXTA) {

        print_log('dual', 'Only next A is possible') if DEBUG;

        # Forward span
        $self->{first}->next;
        # May point to no current

        # Reset buffer
        $self->{buffer}->rewind;
      }

      # No forwarding
      else {
        # $self->{buffer}->clear;
        $self->{doc_id} = undef;
        return;
      };

      # The configuration matches
      if ($check & MATCH) {
        print_log('dual', "! MATCH: $first vs $second!") if DEBUG;
        return 1 ;
      };
    }

    # The first operand is in a document behind the second operand
    elsif ($first->doc_id < $second->doc_id) {

      # Check current constellation - without a second operand
      my $check = $self->check($first, undef);

      print_log('dual', 'A is in a document < B') if DEBUG;

      # Go to the next first
      # TODO: May need a skip
      # Forward was not successful
      unless ($self->{first}->next) {

        # The check is fine - return true
        if ($check & MATCH) {
          print_log('dual', "! MATCH: $first vs NULL!") if DEBUG;

          # However - this means the following 'next' will fail as
          # no A is given.
          return 1;
        };

        # Remove doc_id marker and fail
        $self->{doc_id} = undef;
        return;
      }

      # Forward was successful and there was a match
      elsif ($check & MATCH) {
        print_log('dual', "! MATCH: $first vs $second!") if DEBUG;
        return 1;
      }

      # Forward was successful
      else {
        $self->{buffer}->rewind;
        print_log('dual', 'Forward A to ' . $self->{first}->current) if DEBUG;

        # Go on!
      };
    }

    # The second span is behind
    # $first->doc_id > $second->doc_id
    else {

      # Check current constellation - without a second operand
      my $check = $self->check($first, undef);

      print_log('dual', 'A is in a document > B') if DEBUG;

      # Clean the buffer and move to start
      # TODO:
      #   In case the buffer supports skipping - skip!
      #   Probably implement a buffer ->forget_till(doc_id)
      #   Probably implement forget_and_rewind
      if ($self->{buffer}->forget) {

        # Move to start
        $self->{buffer}->rewind;

        # Check if there is an element on the buffer
        CORE::next if $self->{buffer}->current;

        # Go on!
      };

      # Buffer forward did not work

      print_log('dual', 'Unable to forward buffer - get next posting') if DEBUG;


      # Todo:
      #   Add skipping!

      # Check next posting


      # Go to the next second
      # TODO: May need skip
      # Forward was not succesful
      if (!($self->{second}->next)) {
        print_log('dual', 'There is no next B') if DEBUG;

        # TODO: This may need to match!
        if ($check & MATCH) {

          print_log('dual', "! MATCH: $first vs NULL!") if DEBUG;

          # Move first forward
          # Because it matches it can't be skipped!
          $self->{first}->next;
          return 1;
        };

        # Remove doc_id marker and fail
        $self->{doc_id} = undef;
        return;
      }

      # Forward was successful
      else {
        print_log('dual', 'Try to forward B') if DEBUG;

        # Add current posting to buffer
        $self->{buffer}->remember(
          $self->{second}->current
        );

        # Position finger to last item
        $self->{buffer}->to_end;
        # $second = $self->{buffer}->current;
        # Go on!
      };
    };
  };

  return;
};


1;

__END__
