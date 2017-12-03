package Krawfish::Compile;
use Krawfish::Koral::Result::Match;
use Krawfish::Koral::Result;
use Krawfish::Log;
use Role::Tiny;
use strict;
use warnings;

# TODO:
#   It may be better to use Krawfish::Corpus instead
#
with 'Krawfish::Query';

requires qw/current_match
            match_from_query
            compile
            result/;

# TODO:
#   result() should be in a separate
#   interface, so it is
#   usable in Aggregation::Base as well.

# Krawfish::Compile is the base class for all Compile queries.

# TODO:
#   It may be beneficial to have group, aggregation, sort etc.
#   queries on the root level instead of the intermediate
#   compile level

use constant DEBUG => 0;


# Return match object
sub current_match {
  my $self = shift;

  if (DEBUG) {
    print_log(
      'compile',
      'Current match requested by ' . ref($self)
      );
  };

  my $match = $self->match_from_query or return;

  if (DEBUG) {
    print_log(
      'compile',
      'Current match is ' . $match->to_string
      );
  };

  return $match;
};


# Return the current posting
sub current {
  my $self = shift;

  if (DEBUG) {
    print_log('compile', 'Get current from ' . ref $self);
  };

  return $self->{current} // $self->{query}->current;
};


# Based on the current query this returns either
# a predefined match (when nesting) or creates a match
# based on the query
# May simply be the method
# current_match() in Krawfish::Query!
sub match_from_query {
  my $self = shift;

  print_log('compile', 'Get match from query as ' . ref($self)) if DEBUG;

  my $match;

  # In case, the stream is still valid (for diving in the query cascade),
  # get the match from the query - otherwise construct from current
  # TODO:
  #   This may not be important!
  unless ($self->isa('Krawfish::Compile::Segment::Sort')) {
    # Get current match from query
    $match = $self->{query}->current_match;
  };

  # Not yet defined
  unless ($match) {

    print_log('compile', 'No match found from ' . ref($self->{query})) if DEBUG;

    # Get current object
    my $current = $self->current;

    unless ($current) {
      print_log(
        'compile',
        'No current definable from ' .
          ref($self)) if DEBUG;
      return;
    };

    if (DEBUG) {
      print_log(
        'compile',
        'Current posting is from '. $self->{query}->to_string
      );
    };

    return $self->match_from_posting($current);
  };

  return $match;
};


# Get a match from a span posting
# TODO:
#   Probably make this a method of postings!
#   to_match()!
sub match_from_posting {
  my ($self, $current) = @_;

  # Create new match
  return Krawfish::Koral::Result::Match->new(
    doc_id  => $current->doc_id,
    start   => $current->start,
    end     => $current->end,
    flags   => $current->flags,
    payload => $current->payload->clone,
    ranks   => [$current->ranks]
  );
};


# Check, if a filter is required
sub requires_filter {
  $_[0]->{query}->requires_filter;
};


# Pass filter_by
sub filter_by {
  my ($self, $corpus) = @_;
  return $self->filter_by($corpus);
};


# Get maximum frequency
sub max_freq {
  $_[0]->{query}->max_freq;
};


# Override to compile data
sub compile {
  my $self = shift;

  # TODO:
  #   This is rather for testing purposes

  if (DEBUG) {
    print_log('compile', 'Compile aggregation with ' . ref($self));
  };

  # Get result object
  my $result = $self->result;

  # Add all results
  while ($self->next) {
    if (DEBUG) {
      print_log(
        'compile',
        'Add match ' . $self->current_match->to_string
      );
    };

    $result->add_match($self->current_match);
  };

  # Add aggregations
  if ($self->isa('Krawfish::Compile::Segment::Aggregate')) {

    # Add aggregations to result
    foreach (@{$self->operations}) {
      if (DEBUG) {
        print_log(
          'aggr',
          'Add result to aggr ' . $_->result
        );
      };
      $result->add_aggregation($_->result);
    };
  };

  # Collect more data
  my $query = $self->{query};

  if (DEBUG) {
    print_log('compile', 'Check if ' . ref($query) . ' does compiling');
  };

  if (Role::Tiny::does_role($query, 'Krawfish::Compile')) {
    if (DEBUG) {
      print_log('compile', 'Add result from ' . ref($query));
    };
    $query->result($result)->compile;
  };

  if (DEBUG) {
    print_log(
      'compile',
      'Result is ' . $result
    );
  };
  return $result;
};


# Get aggregation data only
sub aggregate {
  my $self = shift;

  my $result = $self->result;

  # Add aggregations
  if ($self->isa('Krawfish::Compile::Segment::Aggregate')) {

    # Add aggregations to result
    foreach (@{$self->operations}) {
      if (DEBUG) {
        print_log(
          'aggr',
          'Add result to aggr ' . $_->result
        );
      };
      $result->add_aggregation($_->result);
    };
  };

  # Collect more data
  my $query = $self->{query};

  if (DEBUG) {
    print_log('compile', 'Check if ' . ref($query) . ' does compiling');
  };

  if (Role::Tiny::does_role($query, 'Krawfish::Compile')) {
    if (DEBUG) {
      print_log('compile', 'Add result from ' . ref($query));
    };
    $query->result($result)->aggregate;
  };

  $result;
};

# Get result object
sub result {
  my $self = shift;
  if ($_[0]) {
    $self->{result} = shift;
    return $self;
  };
  $self->{result} //= Krawfish::Koral::Result->new;
  return $self->{result};
};


1;
