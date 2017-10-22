package Krawfish::Query::Repetition;
use parent 'Krawfish::Query';
use Krawfish::Util::Buffer;
use Krawfish::Log;
use Krawfish::Posting;
use strict;
use warnings;

use constant DEBUG => 0;

# TODO:
#   Support next_doc()!!!

# TODO:
#   Support next_pos, in case current start
#   position can not succeed, e.g. in case of position

# TODO:
#   Support steps:
#   []{1,30,2}
#   means valid: [][], [][][][], [][][][][], ...


# Constructor
sub new {
  my $class = shift;
  bless {
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
  return if $_[0]->{init}++;
  $_[0]->{span}->next;
  print_log('repeat', 'Init span') if DEBUG;
  # $_[0]->{buffer}->remember($_[0]->{span}->current);

  # Set finger to -1
  $_[0]->{buffer}->backward;
  1;
};


# Move to next posting
sub next {
  my $self = shift;

  $self->_init;

  # Get the buffer
  my $buffer = $self->{buffer};
  my $last;

  while (1) {

    # Buffer is greater than minimum length
    if ($buffer->finger + 1 >= $self->{min}) {
      print_log('repeat', 'Buffer is greater than min ' . $self->{min}) if DEBUG;

      # Buffer is below maximum length
      if ($buffer->finger + 1 <= $self->{max}) {
        print_log('repeat', 'Buffer is below than max ' . $self->{max}) if DEBUG;

        $last = $buffer->current;

        unless ($last) {
          $buffer->clear;
          $buffer->backward;
          CORE::next;
        };

        # Set current
        $self->{doc_id} = $buffer->first->doc_id;
        $self->{start} = $buffer->first->start;
        $self->{end} = $last->end;

        print_log('repeat', 'There is a match - make current match: ' .
                    $self->current) if DEBUG;

        # Forward and remember
        unless ($buffer->next) {

          # Get the current span
          my $current = $self->{span}->current;

          # The current element is fine - remember
          if ($current &&
                $last->doc_id == $current->doc_id &&
                $last->end == $current->start) {

            print_log('repeat', 'Remember the current element (1)') if DEBUG;

            $buffer->remember($current);
            $self->{span}->next;
          }

          # Current element is not fine
          else {
            print_log('repeat', 'No matching doc ids (1)') if DEBUG;
            print_log('repeat', 'Forget the first buffer element (1)') if DEBUG;

            # Shrink the buffer
            $buffer->forget;
            $buffer->finger($self->{min} - 1);
          };
        };

        # Match
        print_log('repeat', "MATCH " . $self->current->to_string) if DEBUG;
        return 1;
      }

      # Buffer is greater than maximum size
      else {
        print_log('repeat', '!Buffer is greater than maximum size') if DEBUG;
        print_log('repeat', 'Forget the first buffer element (2)') if DEBUG;

        # Let the buffer shrink
        # TODO: This will reposition finger with no need
        $buffer->forget;
        $buffer->finger($self->{min} - 1);
      };
    }

    # Buffer has not minimum size yet
    else {
      print_log('repeat', '!Buffer is shorter than minimum: ' . $buffer->to_string) if DEBUG;

      my $last = $buffer->current;

      # Forward and remember
      unless ($buffer->next) {

        # Get the current span
        my $current = $self->{span}->current;

        if (DEBUG) {
          print_log('repeat', "Last element in buffer is " . $last->to_string) if $last;
          print_log('repeat', "Current element is " . $current->to_string) if $current;
        };

        unless ($current) {
          print_log('repeat', 'No current - clear buffer (2)') if DEBUG;
          $buffer->clear;
          $buffer->backward;
          $self->{doc_id} = undef;
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
          $self->{doc_id} = undef;
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

1;
