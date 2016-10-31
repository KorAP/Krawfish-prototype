package Krawfish::Query::Base::Dual;
use parent 'Exporter';
use strict;
use warnings;
use Krawfish::Query::Util::Buffer;
use Krawfish::Posting;

our @EXPORT;

use constant {
  NEXTA  => 1,
  NEXTB  => 2,
  MATCH  => 4
};

@EXPORT = qw/NEXTA NEXTB MATCH/;

# TODO: Improve by skipping to the same document

# This idea is probably wrong.
# There should be a finger in the second span, that can be forwarded but also
# rewinded. The system should be like that:
# Spans:  [pos1][pos2][pos3][pos4][pos5][pos6]
#          ^           ^           ^
#          remember    finger      current
# The finger can return to remember.
# remember can be forwarded.
# Everything between remember and finger is in the candidate list.

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
  print "  >> Init dual spans\n";
  $_[0]->{first}->next;
  $_[0]->{second}->next;
  $_[0]->{buffer}->remember($_[0]->{second}->current);
};


# Current span object
sub current {
  my $self = shift;
  return Krawfish::Posting->new(
    doc   => $self->{doc},
    start => $self->{start},
    end   => $self->{end},
  );
};


# This will advance the two spans
sub next {
  my $self = shift;
  $self->init;

  my ($first, $second);

  while (1) {
    unless ($first = $self->{first}->current) {
      print " ->> No more first items, return false 1\n";
      return;
    };

    unless ($second = $self->{buffer}->current) {
      print " ->> Buffer is empty\n";

      # Forward span
      unless ($self->{first}->next) {
        # May point to no current
        print "  >> return false 2\n";
        return;
      };

      # Reset buffer
      $self->{buffer}->to_start;
      next;
    };

    # TODO: Check if second may not be at the end
    # of the buffer

    # Equal documents - check!
    if ($first->doc == $second->doc) {
      print "  >> Documents are equal - check the configuration\n";
      print "  >> Configuration is $first vs $second\n";

      # Check configuration
      my $check = $self->check($first, $second);

      print "  >> Plan next step based on " . (0 + $check) . "\n";

      # next b is possible
      if ($check & NEXTB) {

        # Only next b is possible
        if (!($check & NEXTA)) {

          # Forget the current buffer
          $self->{buffer}->forget;
        };

        # Forward buffer - or span
        if (!($self->{buffer}->next)) {
          # This will never be true

          print "  >> Unable to forward buffer - get next\n";

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

        # Forward span
        $self->{first}->next;
        # May point to no current

        # Reset buffer
        $self->{buffer}->to_start;
      };

      # The configuration matches
      if ($check & MATCH) {
        print "  !! return Match\n";
        return 1 ;
      };
    }

    # The first span is behind
    elsif ($first->doc < $second->doc) {

      # TODO: This may be wrong, because there may be
      # a second candidate in the same document
      $self->{buffer}->clear;
      $self->{first}->next or return;
    }

    # The second span is behind
    else {
      $self->{buffer}->clear;
      $self->{second}->next or return;
    };
  };

  return;
};


1;

__END__
