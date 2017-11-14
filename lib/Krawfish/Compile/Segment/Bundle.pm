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
    print_log('bundle', 'Get bundle');
  };

  return $self->{current_bundle};
};

sub current {
  return $_[0]->{current};
};


# Move to the next posting in the list,
# maybe in nested bundles.
# These calls methods in Posting::Bundle!
sub next {
  my $self = shift;

  if (DEBUG) {
    print_log('bundle', 'Move to next posting');
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
      $bundle = $self->current_bundle;
      if (DEBUG) {
        print_log('bundle', 'Current bundle to check is ' . $bundle->to_string);
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

  $self->{current} = $bundle->current;

  if (DEBUG) {
    print_log('bundle', 'Set current posting to ' . $self->{current}->to_string);
  };

  return 1;
};


# Get frequency
sub max_freq {
  $_[0]->{query}->max_freq;
};


1;
