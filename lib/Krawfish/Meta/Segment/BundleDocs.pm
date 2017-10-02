package Krawfish::Meta::Segment::BundleDocs;
use parent 'Krawfish::Meta';
use Krawfish::Log;
use Krawfish::Posting::DocBundle;
use strict;
use warnings;

# Bundle matches in the same document.

use constant DEBUG => 1;

sub new {
  my $class = shift;
  bless {
    query => shift,
    next_item => undef,
    buffer => undef
  }, $class;
};


# Bundle the current match
sub current_bundle {
  my $self = shift;

  if (DEBUG) {
    print_log('d_bundle', 'Get bundle');
  };

  return $self->{current_bundle} if $self->{current_bundle};

  my $first = $self->{next_item};

  # Need a next() first
  return unless $first;

  my $bundle = Krawfish::Posting::DocBundle->new($first);
  my $query = $self->{query};

  if (DEBUG) {
    print_log('d_bundle', 'Start bundle with ' . $first->to_string);
  };


  # There is a next entry
  my $next;
  while ($query->next) {
    $next = $query->current;

    # Documents are identical - bundle
    if ($next->doc_id == $first->doc_id) {
      $bundle->add($next);
    }

    # Remember the next bundle
    else {
      $self->{buffer} = $next;
      last;
    };
  };

  $self->{current_bundle} = $bundle;

  return $bundle;
};


sub max_freq {
  $_[0]->{query}->max_freq;
};

sub current {
  return $_[0]->{query}->current;
};


# Move to next bundle
sub next {
  my $self = shift;
  $self->{current_bundle} = undef;

  if ($self->{buffer}) {
    $self->{next_item} = $self->{buffer};
    $self->{buffer} = undef;
  }

  # Move forward
  elsif ($self->{query}->next) {
    $self->{next_item} = $self->{query}->current;
  }

  # Can't move forward
  else {
    $self->{next_item} = undef;
    return;
  };

  return 1;
};


sub to_string {
  'bundleDocs(' . $_[0]->{query}->to_string . ')';
};


1;
