package Krawfish::Compile::Segment::Enrich::Snippet::Context::Span;
use Krawfish::Posting::Forward;
use Krawfish::Log;
use strict;
use warnings;

use constant DEBUG => 0;

sub new {
  my $class = shift;
  # foundry_id, layer_id, anno_id, count
  #
  # The number of elements left or right
  # to the match. Defaults to 0
  # (so: only expand to the element)
  #   count

  # Maximum number of tokens
  #   max
  bless { @_ }, $class;
};


# Reposition the pointer to the start position of the context
sub start {
  my ($self, $pointer) = @_;

  # It is expected that the pointer is
  # already positioned to the match start.

  my $left_start             = $pointer->pos;
  my $left_start_ext_char    = 0;
  my $right_min_end          = $pointer->pos;
  my $right_min_end_ext_char = 0;

  # Do not search beyond maximum tokens
  my $max = $self->{max};

  # Count the number of valid elements to the left
  my $count = $self->{count};

  # As long as it is allowed, iterate through tokens
  while ($max-- > 0) {

    # Get current forward token (a Krawfish::Posting::Forward)
    my $current = $pointer->current;

    # Check if the token is relevant for annotation
    if (my $anno = $current->annotation(
      $self->{foundry_id},
      $self->{layer_id},
      $self->{anno_id},
    )) {
      # Annotation was found - get span length!

      # Get the first annotation (that has the shortest span length)
      # TODO:
      #   It may be beneficial to check, if there is a better length,
      #   e.g. one that surrounds the match
      my $anno_data = $anno->[0];

      # The first part of the annotation is the end position
      my $anno_end = $anno_data->[0];

      # Remember the end position, if it exceeds the min value
      $right_min_end = $anno_end if $right_min_end > $anno_end;

      # Remember the starting position!
      $left_start = $pointer->pos;

      # TODO:
      #   Check for character extensions!

      # Element was found - and it's the last time it's valid
      last if --$count < 0;
    }

    # Element is not found at position
    else {

      # Maximum tokens exceeded
      last if $max-- < 1;

      # Move backwards
      $pointer->prev;
    };
  };

  # Move pointer to new start
  if ($pointer->pos < $left_start) {
    $pointer->skip_pos($left_start)
  };

  # Return all relevant information
  return (
    $left_start,
    $left_start_ext_char,
    $right_min_end,
    $right_min_end_ext_char
  );
};



# Get left context and minimal right extension
sub left {

  # TODO:
  #   THIS IS DEPRECATED!

  my ($self, $match, $pointer) = @_;

  # The context as an array of preceeding strings and term_ids
  my @context = ();

  # Do not search beyond maximum tokens
  my $max        = $self->{max_left};
  my $count      = $self->{count_left};
  my $last_match = undef;

  # Get the start position of the match
  # Move to that position (may be before current pointer position
  unless ($pointer->skip_pos($match->start)) {
    warn "pointer currently can't be repositioned";
  };

  # Remember the match position
  my $remember_position = $pointer->current;

  # As long as it is allowed, iterate through tokens
  while ($max-- > 0) {

    # Get current forward token
    my $current = $pointer->current;
    my $pos = $current->pos;

    # Check if the token is relevant for annotation
    if (my $anno = $current->annotation(
      $self->{foundry_id},
      $self->{layer_id},
      $self->{anno_id},
    )) {
      # Annotation was found - get span length!

      # Get the first annotation (that has the shortest span length)
      # TODO:
      #   It may be beneficial to check, if there is a better length,
      #   e.g. one that surrounds the match
      my $anno_data = $anno->[-1];

      # The first part is the end position
      my $anno_end = $anno_data->[0];

      # TODO:
      #   DO something with $anno_end

      # Element was found
      if ($count-- < 0) {

        # The span is not the start of the match
        # (in which the part is already in the match)
        if ($pos != $match->start) {
          # Add token to context
          unshift @context, Krawfish::Posting::Forward->new(
            term_id        => $current->term_id,

            # Preceding data may need to be cut!
            preceding_data => $current->preceding_data
          );
        };

        # The requirement is fulfilled
        $last_match = undef;
        last;
      };

      # remember last match to gracefully cut all matches
      $last_match = $max;
    }

    # Element is not found at position
    else {

      # The token is part of the match (and therefore not part of the context)
      if ($pos == $match->start) {
        # Add token to context
        unshift @context, Krawfish::Posting::Forward->new(
          term_id        => 0,
          preceding_data => $current->preceding_data
        );
      };

      # Add token to context
      unshift @context, Krawfish::Posting::Forward->new(
        term_id        => $current->term_id,
        preceding_data => $current->preceding_data
      );

      # Maximum tokens exceeded
      if ($max-- < 1) {
        last;
      };

      # Move backwards
      $pointer->prev;
    };
  };

  # There is a last match to trim
  if ($last_match) {
    # TODO:
    #   Cut the context array to the last match
    # TODO:
    #   Cut the last preceding data part as well!
  };

  # TODO
  #   Revert array
};

sub right {
  ...
};

sub to_string {
  my $self = shift;
  my $str = 'span(';
  $str .= '#' . $self->{foundry_id} . '/#' . $self->{layer_id} . '=#' . $self->{anno_id} . ',';
  return $str . $self->{count} . ',' . $self->{max} . ')';
};


1;
