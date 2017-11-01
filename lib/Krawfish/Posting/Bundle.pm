package Krawfish::Posting::Bundle;
use Role::Tiny;
with 'Krawfish::Posting';
# TODO:
#   Also have a PostingIterator type
#   with next() and current()
use Krawfish::Log;
use overload '""' => sub { $_[0]->to_string }, fallback => 1;
use warnings;
use strict;

# This is a container class for multiple Krawfish::Posting objects,
# used for (among others) sorting.

# This implements a posting as well as an iterator with next() and current().

# TODO:
#   Make this rather a buffer bundle instead of a posting.

# TODO:
#   Make unbundle() an iterator!

use constant DEBUG => 0;

# Constructor
sub new {

  # Bless an array
  my $self = bless {
    list => [],
    pos => -1,
    current => undef
  }, shift;

  # Add passed items
  foreach (@_) {
    unless ($self->add($_)) {
      warn "$_ is not a valid match object";
      return;
    };
  };
  $self;
};


# Return document id of the bundle
sub doc_id {
  return unless $_[0]->size;
  $_[0]->{list}->[0]->doc_id;
};


# Start position not available
#sub start {
#  warn 'Not available on bundle';
#  0;
#};


# End position not available
#sub end {
#  warn 'Not available on bundle';
#  0;
#};


# Clone posting object
sub clone {
  my $self = shift;
  return __PACKAGE__->new(@$self);
};


# Payload not really available
sub payload {
  Krawfish::Posting::Payload->new;
};


# The number of items in the bundle
sub size {
  scalar @{$_[0]->{list}};
};


# Get the number of matches in the bundle
sub matches {
  my $self = shift;
  my $matches = 0;
  foreach (@{$self->{list}}) {
    $matches += $_->matches;
  };
  return $matches;
};


# Add match to match array
sub add {
  my ($self, $obj) = @_;

  if (DEBUG) {
    print_log('p_bundle', 'Add ' . $obj->to_string . ' to bundle');
  };

  # Not an object
  return unless $obj;

  my $list = $self->{list};

  # Push object to list
  if (Role::Tiny::does_role($obj, 'Krawfish::Posting')) {
    push @$list, $obj;
    return 1;
  };
  return;
};


# Stringification
sub to_string {
  my $self = shift;
  return '[' . join ('|', map { $_->to_string } @{$self->{list}}) . ']';
};


# The bundle may contain multiple items and these
# items may contain bundles.
# Current will contain a single posting that may
# become a match.
sub current {
  return $_[0]->{current};
};


# Get next item from bundle,
# or bundled bundle, or a bundled-bundled bundle ...
sub next {
  my $self = shift;

  my $init = 0;

  # Bundle is not yet initialized!
  if ($self->{pos} < 0) {

    if (DEBUG) {
      print_log('p_bundle', 'Bundle is not yet initialized');
    };

    # This is the current item
    $self->{pos}++;
    $init = 1;
  };

  my $current = $self->{list}->[$self->{pos}];

  if (DEBUG && $current) {
    print_log('p_bundle', 'Current item is ' . $current->to_string);
  };

  # The bundle bundles bundles
  if ($current && Role::Tiny::does_role($current, 'Krawfish::Posting::Bundle')) {

    if (DEBUG) {
      print_log('p_bundle', 'Move to next item in bundled bundle');
    };

    unless ($current->next) {
      $self->{pos}++;

      # End of list is exceeded
      if ($self->{pos} >= $self->size) {
        $self->{current} = undef;
        return;
      };

      $current = $self->{list}->[$self->{pos}];
    };

    $self->{current} = $current->current;
    return 1;
  }

  elsif (!$init) {

    if (DEBUG) {
      print_log('p_bundle', 'Move to next item in simple bundle');
      print_log('p_bundle', 'The bundle has the size of ' . $self->size);
    };

    $self->{pos}++;
  };

  # This does not bundle bundles

  # End of list is exceeded
  if ($self->{pos} >= $self->size) {
    $self->{current} = undef;
    return;
  };

  if (DEBUG) {
    print_log('p_bundle', 'Move to next item in bundle at pos ' . $self->{pos});
  };

  $self->{current} = $self->{list}->[$self->{pos}];

  if (DEBUG) {
    print_log('p_bundle', 'New current is ' . $self->{current}->to_string);
  };

  return 1;
};


# Reset internal position in bundle
sub reset {
  $_[0]->{pos} = -1;
};


# Get item in list
sub item {
  my ($self, $item) = @_;
  $self->{list}->[$item];
};


1;
