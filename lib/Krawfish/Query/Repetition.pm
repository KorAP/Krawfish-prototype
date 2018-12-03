package Krawfish::Query::Repetition;
use strict;
use warnings;
use Role::Tiny::With;
use Krawfish::Util::Buffer;
use Krawfish::Log;
use Krawfish::Posting;

with 'Krawfish::Query';

use constant DEBUG => 0;

# TODO:
#   Support skip_doc()!!!

# TODO:
#   Support next_pos, in case current start
#   position can not succeed, e.g. in case of position

# Constructor
sub new {
  my $class = shift;
  return bless {
    span => shift,
    min => shift,
    max => shift,
    buffer => Krawfish::Util::Buffer->new
  }, $class;
};


# Clone query
sub clone {
  my $self = shift;
  __PACKAGE__->new(
    $self->{span}->clone,
    $self->{min},
    $self->{max}
  );
};


# Initialize spans and buffer
sub _init {
  my $self = shift;

  return if $self->{init}++;

  print_log('repeat', 'Init span ' . $self->{span}->to_string . ' for ' . $self->to_string) if DEBUG;

  $self->{span}->next;
  # $_[0]->{buffer}->remember($_[0]->{span}->current);

  # Set finger to -1
  $self->{buffer}->backward;
  1;
};


# Move to next posting
sub next {
  my $self = shift;

  $self->_init;

  # Get the buffer
  my $buffer = $self->{buffer};
  my $last;
  $self->{doc_id} = undef;

  while (1) {

    if (DEBUG) {
      print_log('repeat', 'Check buffer for match ' . $buffer->to_string);
    };

    # Buffer is greater than minimum length
    # # Old: ($buffer->finger + 1)
    if ($buffer->size >= $self->{min}) {
      if (DEBUG) {
        print_log(
          'repeat',
          'Buffer is greater equal than min ' . $self->{min}
        );
      };

      # Buffer is below maximum length
      # # Old: ($buffer->finger + 1)
      if ($buffer->size <= $self->{max}) {
        if (DEBUG) {
          print_log(
            'repeat',
            'Buffer is smaller equal than max ' . $self->{max} . ' at ' . $buffer->finger
          );
        };

        $last = $buffer->current;

        if (!$last) {
          $buffer->clear;
          $buffer->backward;
          CORE::next;
        };

        # Set current
        my $first = $buffer->first;
        $self->{doc_id} = $first->doc_id;
        $self->{flags}  = $first->flags;
        $self->{start}  = $first->start;
        $self->{end}    = $last->end;

        if (DEBUG) {
          print_log(
            'repeat',
            'There is a match - make current MATCH: ' . $self->current
          );
        };

        # Forward and remember
        unless ($buffer->next) {

          # Get the current span
          my $current = $self->{span}->current;

          if (DEBUG) {
            if ($last) {
              print_log('repeat', 'Last element in buffer is ' . $last->to_string . ' (1)');
            };
            if ($current) {
              print_log('repeat', 'Current element is ' . $current->to_string . ' (1)');
            };
          };

          # The current element is fine - remember
          if ($current &&
                $last &&
                $last->doc_id == $current->doc_id &&
                $last->end == $current->start) {

            print_log('repeat', 'Remember the current element (1)') if DEBUG;

            $buffer->remember($current);
            $self->{span}->next;
          }

          # Current element is not fine
          elsif ($last) {
            if (DEBUG) {
              if ($current) {
                if ($last->doc_id != $current->doc_id) {
                  print_log('repeat', 'No matching doc ids (1)');
                }
                elsif ($last->end != $current->start) {
                  print_log('repeat', 'There is a gap between last and current');
                };
              }
              elsif (!$current) {
                print_log('repeat', 'There is no more current');
              }
              elsif (!$last) {
                print_log('repeat', 'There is no more last');
              };
              print_log('repeat', 'Forget the first buffer element (1)');
              print_log('repeat', 'Maybe the buffer contains a match with another offset');
            };

            # Shrink the buffer
            $buffer->forget;

            # If the buffer is empty now - move to -1
            # TODO:
            #   This is horribly complicated, but works for the moment
            if ($buffer->size < $self->{min}) {
              $buffer->backward;
            }

            # The finger needs to be sat back, but not before the
            # minimum possible repetition
            else {
              $buffer->finger($self->{min} - 1);
            };
            # $buffer->backward;
            # CORE::next;
          };
        };

        # Match
        print_log('repeat', "MATCH " . $self->current->to_string) if DEBUG;
        return 1;
      }

      # Buffer is greater than maximum size
      else {
        if (DEBUG) {
          print_log('repeat', '!Buffer is greater than max ' . $self->{max});
          print_log('repeat', 'Forget the first buffer element (2)');
        };

        # Let the buffer shrink
        # TODO: This will reposition finger with no need
        $buffer->forget;

        # If the buffer is empty now - move to -1
        # TODO:
        #   This is horribly complicated, but works for the moment
        if ($buffer->size < $self->{min}) {
          $buffer->clear;
          $buffer->backward;
        }

        # The finger needs to be sat back, but not before the
        # minimum possible repetition
        else {
          $buffer->finger($self->{min} - 1);
        };

        # $buffer->backward;
        # $buffer->finger($self->{min} - 1);
      };
    }

    # Buffer has not minimum size yet
    else {

      # Get the last element from buffer
      $last = $buffer->current;

      # Get the current span
      my $current = $self->{span}->current;

      if (DEBUG) {
        print_log('repeat', '!Buffer is smaller than min ' . $self->{min});
        print_log('repeat', 'Last element in buffer is ' . $last->to_string . ' (2)') if $last;
        print_log('repeat', 'Current element is ' . $current->to_string . ' (2)') if $current;

      };

      # The buffer and current are divided - clear the buffer
      if ($last &&
            $current &&
            ($last->doc_id != $current->doc_id ||
             $last->end != $current->start)) {
        print_log('repeat', 'Current element and last buffer item are disjointed - clear buffer');
        $buffer->clear;
        $buffer->backward;
        CORE::next;
      };

      # Forward and remember
      unless ($buffer->next) {

        if (DEBUG) {
          if ($last) {
            print_log('repeat', "Last element in buffer was " . $last->to_string . ' (3)');
          };
          if ($current) {
            print_log('repeat', "Current element is " . $current->to_string . ' (3)');
          };
          print_log('repeat', 'Current buffer is ' . $buffer->to_string);
        };

        unless ($current) {
          print_log('repeat', 'No current - clear buffer (2)') if DEBUG;
          $buffer->clear;
          $buffer->backward;
          return 1 if $self->{doc_id};
          # $self->{doc_id} = undef;
          return;
        }

        elsif (!$last || (
          $current &&
            $last->doc_id == $current->doc_id &&
            $last->end == $current->start
          )) {
          print_log('repeat', 'Remember the current element (2)') if DEBUG;
          $buffer->remember($current);
          $self->{span}->next;
        }
        else {
          print_log('repeat', 'No matching doc ids (2)') if DEBUG;
          print_log('repeat', 'Clear buffer') if DEBUG;
          $buffer->clear;
          $buffer->backward;
          return 1 if $self->{doc_id};
          # $self->{doc_id} = undef;
          return;
        };
      };
    };
  };
};


# Stringification
sub to_string {
  my $self = shift;
  my $str = 'rep(';
  $str .= $self->{min} . '-' . $self->{max} . ':';
  $str .= $self->{span}->to_string;
  return $str . ')';
};


# Get maximum frequency, based on the occurrence
# of the span, multiplied by the difference of
# min and max values, so
#
#   freq([a]{3}) == freq([a])
#   freq([a]{1,2}) == freq([a])*2
sub max_freq {
  my $self = shift;
  $self->{span}->max_freq * ($self->{max} - $self->{min} + 1)
};


# Filter query by VC
sub filter_by {
  my ($self, $corpus) = @_;
  $self->{span} = $self->{span}->filter_by($corpus);
  return $self;
};


# Requires filtering
sub requires_filter {
  return $_[0]->{span}->requires_filter;
};


# Move to next document
sub next_doc {
  my $self = shift;

  $self->_init;

  my $current = $self->current or return;
  my $current_doc_id = $current->doc_id;

  if (DEBUG) {
    print_log('repeat', refaddr($self) . ": go to next doc following $current_doc_id");
    print_log('repeat', 'Buffer is ' . $self->{buffer}->to_string)
  };

  if ($self->{span}->current->doc_id == $current->doc_id) {
    $self->{span}->next_doc or return;
  }

  $self->{buffer}->clear;
  $self->{buffer}->backward;

  $self->next or return;

  return 1;
};

1;
