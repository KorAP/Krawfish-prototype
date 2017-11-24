package Krawfish::Compile::Segment::Bundle;
use Role::Tiny;
use Krawfish::Log;
use strict;
use warnings;

requires qw/current_bundle
            next_bundle/;


# This role represents bundles of postings
# (or bundles of bundles of postings) sorted by a certain criterion.


use constant DEBUG => 0;


# Bundle the current match
sub current_bundle {
  my $self = shift;

  if (DEBUG) {
    print_log(
      'bundle',
      'Get current bundle in ' . ref($self),
      '  is ' .
        ($self->{current_bundle} ? $self->{current_bundle}->to_string : '????'),
      '  called from ' . join(', ', caller)
      );
  };

  return $self->{current_bundle};
};


# Get current posting
sub current {
  my $self = shift;

  if (DEBUG) {
    print_log(
      'bundle',
      'Get current from ' . ref($self),
      '  is ' .
        ($self->{current} ? $self->{current}->to_string : '???'),
      '  called from ' . join(', ', caller),
      '  current bundle is ' .
        ($self->{current_bundle} ? $self->{current_bundle}->to_string : '???'),
    );
  };

  return $self->{current};
};


# Move to the next posting in the list,
# maybe in nested bundles.
# These calls methods in Posting::Bundle!
sub next {
  my $self = shift;

  $self->{match} = undef;

  if (DEBUG) {
    print_log('bundle', 'Move to next posting in ' . ref($self));
  };

  # Get current bundle
  my $bundle = $self->current_bundle;

  # Check next in bundle
  while (!$bundle || !$bundle->next) {

    if (DEBUG) {
      if (!$bundle) {
        print_log('bundle', 'Current bundle does not exist yet or there is none');
      }
      else {
        print_log('bundle', 'There is no more entry in current bundle');
      };

      print_log('bundle', 'Move to next bundle');
    };


    # There are more bundles
    if ($self->next_bundle) {

      if (DEBUG) {
        print_log(
          'bundle',
          'Moved to next bundle'
        );
      };

      # Get current bundle
      $bundle = $self->current_bundle;

      if (DEBUG) {
        print_log(
          'bundle',
          'Current bundle to check is ' .
            $bundle->to_string
          );
      };
    }

    # There are no more bundles
    else {

      if (DEBUG) {
        print_log('bundle', 'No more bundles');
      };

      $self->{current} = undef;
      return;
    };
  };

  if (DEBUG) {
    print_log(
      'bundle',
      'Copy the ranks from ' . ref($bundle) . '=' . $bundle->to_string,
      '  to posting [' . join(', ', $bundle->ranks) . '] in ' .
        ref($self)
    );
  };

  # Set current match
  $self->{current} = $bundle->current;

  # TODO:
  #   Remembering ranks may not be relevant as long as criteria are
  #   fetched using the rank again!

  # In case of a bundled bundle, get the rank of the first item
  if ($bundle && Role::Tiny::does_role($bundle, 'Krawfish::Posting::Bundle')) {

    # TODO:
    #   I am not sure about the scenarios with multiple bundled bundles though
    $self->{current}->ranks($bundle->item(0)->ranks);
  }

  # In case of a bundled posting
  else {
    $self->{current}->ranks($bundle->ranks);
  };

  if (DEBUG) {
    print_log(
      'bundle',
      'Set current posting to ' .
        $self->{current}->to_string .
        ' from ' . ref($self)
      );
  };

  return 1;
};


# Get frequency
sub max_freq {
  $_[0]->{query}->max_freq;
};


1;
