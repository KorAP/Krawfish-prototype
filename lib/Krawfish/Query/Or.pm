package Krawfish::Query::Or;
use parent 'Krawfish::Query';
use Krawfish::Log;
use strict;
use warnings;

use constant DEBUG => 0;


# Constructor
sub new {
  my $class = shift;
  bless {
    first => shift,
    second => shift
  }, $class;
};


# Clone query
sub clone {
  my $self = shift;
  __PACKAGE__->new(
    $self->{first}->clone,
    $self->{second}->clone
  );
};


# Initialize
sub _init  {
  return if $_[0]->{init}++;
  if (DEBUG) {
    print_log(
      'or',
      'Init ' . $_[0]->{first}->to_string . ' and ' . $_[0]->{second}->to_string
    );
  };
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

  if (DEBUG) {
    print_log(
      'or',
      'Which alternative is first in order: ' .
      ($first ? $first->to_string : '?') . ' or ' .
        ($second ? $second->to_string : '?')
    );
  };

  # First span is no longer available
  if (!$first) {

    unless ($second) {
      $self->{doc_id} = undef;
      return;
    };
    print_log('or', 'Current is second (a) - no first available') if DEBUG;
    $curr = 'second';
  }

  # Second span is no longer available
  elsif (!$second) {
    print_log('or', 'Current is first (b) - no second available') if DEBUG;
    $curr = 'first';
  }

  elsif ($first->doc_id < $second->doc_id) {
    print_log('or', 'Current is first (based on document id)') if DEBUG;
    $curr = 'first';
  }
  elsif ($first->doc_id > $second->doc_id) {
    print_log('or', 'Current is second (based on document id)') if DEBUG;
    $curr = 'second';
  }
  elsif ($first->start < $second->start) {
    print_log('or', 'Current is first (based on start position)') if DEBUG;
    $curr = 'first';
  }
  elsif ($first->start > $second->start) {
    print_log('or', 'Current is second (based on start position)') if DEBUG;
    $curr = 'second';
  }
  elsif ($first->end < $second->end) {
    print_log('or', 'Current is first (based on end position)') if DEBUG;
    $curr = 'first';
  }
  elsif ($first->end > $second->end) {
    print_log('or', 'Current is second (based on end position)') if DEBUG;
    $curr = 'second';
  }
  else {
    print_log('or', 'Current is first (just because both are identical)') if DEBUG;
    $curr = 'first';
  };

  my $curr_post    = $self->{$curr}->current;
  $self->{doc_id}  = $curr_post->doc_id;
  $self->{flags}   = $curr_post->flags;
  $self->{start}   = $curr_post->start;
  $self->{end}     = $curr_post->end;
  $self->{payload} = $curr_post->payload->clone;

  if (DEBUG) {
    print_log('or', 'So current is ' . $self->current->to_string);
    print_log('or', "Next on $curr");
  };
  $self->{$curr}->next;
  return 1;
};


# Stringification
sub to_string {
  my $self = shift;
  return 'or(' . $self->{first}->to_string . ',' . $self->{second}->to_string . ')';
};


# Get maximum frequency
sub max_freq {
  my $self = shift;

  # Frequencies are unknown
  if ($self->{first}->max_freq == -1 || $self->{second}->max_freq == -1) {
    return -1;
  }

  # Combine frequencies
  else {
    return $self->{first}->max_freq + $self->{second}->max_freq;
  };
};


# Return the complexity of the operation
# This is required to optimize filtering
sub complex {
  my $self = shift;

  # Operation is complex
  return 1 if $self->{first}->complex || $self->{second}->complex;

  # Operation is simple
  return 0;
};


# Filter query by VC
sub filter_by {
  my ($self, $corpus) = @_;

  # If both operands are simple
  # (e.g. leafs, or-queries on leafs)
  # it's beneficial to let the filter stop here
  # and not check on each of the branches.
  #
  #   Example:
  #     filter(corpus,or(a,b))
  #       vs.
  #     or(filter(corpus,a),filter(corpus,b))
  #
  if ($self->complex) {
    $self->{first} = $self->{first}->filter_by($corpus);
    $self->{second} = $self->{second}->filter_by($corpus);
    return $self;
  };

  return Krawfish::Query::Filter->new(
    $self, $corpus->clone
  );
};


# Requires filtering
sub requires_filter {
  my $self = shift;
  if ($self->{first}->requires_filter) {
    return 1;
  }
  elsif ($self->{second}->requires_filter) {
    return 1;
  };
  return 0;
};


1;
