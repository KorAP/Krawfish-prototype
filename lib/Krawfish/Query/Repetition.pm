package Krawfish::Query::Repetition;
use Krawfish::Query::Util::Buffer;
use Krawfish::Posting;
use strict;
use warnings;

sub new {
  my $class = shift;
  bless {
    span => shift,
    min => shift,
    max => shift,
    buffer => Krawfish::Query::Util::Buffer->new
  }, $class;
};


# Current span object
sub current {
  my $self = shift;
  return Krawfish::Posting->new(
    doc_id => $self->{doc_id},
    start  => $self->{start},
    end    => $self->{end},
  );
};


# Initialize spans and buffer
sub init {
  return if $_[0]->{init}++;
  $_[0]->{span}->next or return;
  print "  >> Init span\n";
#  $_[0]->{buffer}->remember($_[0]->{span}->current);
  1;
};

sub next {
  my $self = shift;
  $self->init;

  # Get the buffer
  my $buffer = $self->{buffer};
  my $last;

  while (1) {
    my $current = $self->{span}->current;

    # Buffer is greater than minimum length
    if ($buffer->size >= $self->{min}) {
      print '  >> Buffer is greater than min ' . $self->{min} . "\n";

      # Buffer is below maximum length
      if ($buffer->size <= $self->{max}) {
        print '  >> Buffer is below than max ' . $self->{max} . "\n";

        $last = $buffer->last;

        # Set current
        $self->{doc_id} = $buffer->first->doc_id;
        $self->{start} = $buffer->first->start;
        $self->{end} = $last->end;

        print "  >> There is a match - make current match: " .
          $self->current . "\n";


        # The current element is fine - remember
        if ($last->doc_id == $current->doc_id &&
              $last->end == $current->start) {

          print "  >> Remember the current element (1)\n";

          # Forward and remember
          $buffer->remember($current);
          $self->{span}->next;
        }

        # Current element is not fine
        else {
          print "  >> No matching doc ids\n";
          print "  >> Forget the first buffer element (1)\n";

          # Shrink the buffer
          $buffer->forget;
        };

        # Match
        print "  -> MATCH\n";
        return 1;
      }

      # Buffer is greater than maximum size
      else {
        print "  >> !Buffer is greater than maximum size\n";
        print "  >> Forget the first buffer element (2)\n";

        # Let the buffer shrink
        # TODO: This will reposition finger with no need
        $buffer->forget;
      };
    }

    # Buffer has not minimum size yet
    else {
      print "  >> !Buffer is shorter than minimum: " . $buffer->to_string . "\n";

      # No current
      unless ($current) {

        print "  >> No current - clear buffer\n";
        $buffer->clear;

        # No further matches
        return;
      };

      my $last = $buffer->last;

      print "  >> Last element in buffer is " . $last->to_string . "\n" if $last;
      print "  >> Current element is " . $current->to_string . "\n";
      if (!$last || ($last->doc_id == $current->doc_id &&
                       $last->end == $current->start)
        ) {
        print "  >> Remember the current element (2)\n";
        $buffer->remember($current);
        $self->{span}->next;
      }
      else {
        print "  >> No matching doc ids - clear buffer\n";
        $buffer->clear;
      }
    };
  };
};


sub to_string {
  my $self = shift;
  my $str = 'rep(';
  $str .= $self->{min} . '-' . $self->{max} . ':';
  $str .= $self->{span}->to_string;
  return $str . ')';
};

1;
