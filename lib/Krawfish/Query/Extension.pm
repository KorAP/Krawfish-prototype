package Krawfish::Query::Extension;
use strict;
use warnings;
use Krawfish::Util::RepetitionPattern;
use Role::Tiny::With;

with 'Krawfish::Query';

use constant DEBUG => 0;

# This query adds subtokens to the left or the right
# of a matching span
#
# TODO:
#   Support gaps like with Constraint::InBetween

# TODO:
#   Support classes

# TODO:
#   Support patterns, so
#   []{2}{1,30}
#   means valid: [][], [][][][], [][][][][], ...
#   Realisation as a Krawfish::Util::RepetitionPattern

# Constructor
sub new {
  my $class = shift;
  bless {
    left => shift,
    span => shift,
    pattern => Krawfish::Util::RepetitionPattern->new(@{shift()}),
    buffer => Krawfish::Util::Buffer->new
  }, $class;
  # min, max ...
};


# Clone query
sub clone {
  my $self = shift;
  return __PACKAGE__->new(
    $self->{left},
    $self->{span}->clone,
    $self->{pattern}->ranges
  );
};


# Check the configuration
sub check {
  ...
};


# Stringification
sub to_string {
  my $self = shift;
  my $string ='ext(';
  $string .= $self->{left} ? '<' : '>';
  $string .= ':' . $self->{pattern}->to_string;
  return $string . ':' . $self->{span}->to_string . ')';
};


# Get maximum frequency
# TODO:
#   Introduce a cardinality() method to Krawfish::Util::RepetitionPattern
sub max_freq {
  return $_[0]->{span}->max_freq * $_[0]->{pattern}->cardinality;
};


# Filter query by VC
sub filter_by {
  ...
};


# Requires filtering
sub requires_filter {
  return $_[0]->{span}->requires_filter;
};


# Move to next posting
sub next {
  my $self = shift;
  # right extensions just add
  # right tokens and match,
  # as long as the document span is not reached

  # left extensions require a buffer
  # with the size of max (+1?) to hold
  # candidates

  $self->{span}->next;

  my $buffer = $self->{buffer};

  if ($buffer->next) {
    return $buffer->current;
  }
  else {

    # For right!
    my $current = $self->{span}->current;

    # Extend the match with min to max tokens to the right
    for (my $i = $self->{min}; $i <= $self->{max}; $i++) {

      # Create new extended posting
      my $posting = Krawfish::Posting::Span->new(
        doc_id  => $current->doc_id,
        start   => $current->start,
        end     => $current->end + $i, # This does not check for text end
        payload => $current->payload,
        flags   => $current->flags
      );

      # Remember in buffer
      $buffer->remember($posting);
    };
  }
};

1;
