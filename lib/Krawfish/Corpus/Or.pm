package Krawfish::Corpus::Or;
use parent 'Krawfish::Corpus';
use Krawfish::Log;
use strict;
use warnings;

use constant DEBUG => 0;

# TODO:
#   Support class flags

sub new {
  my $class = shift;
  bless {
    first => shift,
    second => shift,
    doc_id => -1,
    flags => 0b0000_0000_0000_0000
  }, $class;
};


# Clone query object
sub clone {
  my $self = shift;
  __PACKAGE__->new(
    $self->{first}->clone,
    $self->{second}->clone
  );
};


# Initialize query
sub _init  {
  return if $_[0]->{init}++;
  $_[0]->{first}->next;
  $_[0]->{second}->next;
};


# Move to next posting
sub next {
  my $self = shift;
  $self->_init;

  my $first = $self->{first}->current;
  my $second = $self->{second}->current;

  my $curr = 'first';

  while ($first || $second) {

    # First span is no longer available
    if (!$first) {
      print_log('vc_or', 'Current is second operand (a)') if DEBUG;
      $curr = 'second';
    }

    # Second span is no longer available
    elsif (!$second) {
      print_log('vc_or', 'Current is first operand (b)') if DEBUG;
      $curr = 'first';
    }

    elsif ($first->doc_id < $second->doc_id) {
      print_log('vc_or', 'Current is first operand (1)') if DEBUG;
      $curr = 'first';
    }
    elsif ($first->doc_id > $second->doc_id) {
      print_log('vc_or', 'Current is second operand (1)') if DEBUG;
      $curr = 'second';
    }
    else {
      print_log('vc_or', 'Current is first operand (4)') if DEBUG;
      $curr = 'first';
    };

    # Get the current posting of the respective operand
    my $curr_post = $self->{$curr}->current;

    # Only return unique identifier
    if ($self->{doc_id} == $curr_post->doc_id) {

      if (DEBUG) {
        print_log('vc_or', 'Document ID already returned: '. $self->{doc_id});
      };

      # Forward
      $self->{$curr}->next;

      # Set current docs
      $first = $self->{first}->current;
      $second = $self->{second}->current;

      CORE::next;
    };

    $self->{doc_id} = $curr_post->doc_id;

    if (DEBUG) {
      print_log('vc_or', 'Current doc is ' . $self->current->to_string);
      print_log('vc_or', "Next on $curr operand");
    };

    $self->{$curr}->next;
    return 1;
  };

  $self->{doc_id} = undef;
  return;
};


# Stringification
sub to_string {
  my $self = shift;
  return 'or(' . $self->{first}->to_string . ',' . $self->{second}->to_string . ')';
};


# Get maximum frequency
sub max_freq {
  my $self = shift;
  $self->{first}->max_freq + $self->{second}->max_freq;
};


1;
