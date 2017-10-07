package Krawfish::Meta::Segment::BundleDocs;
use parent 'Krawfish::Meta::Segment::Bundle';
use Krawfish::Log;
use Krawfish::Posting::List;
use strict;
use warnings;

# Bundle matches in the same document.

# TODO:
#   The problem with the current approch is, that next_bundle
#   will bundle the next doc - without asking if the doc
#   is relevant.

use constant DEBUG => 1;

sub new {
  my $class = shift;
  bless {
    query => shift,
    buffer => undef
  }, $class;
};


sub clone {
  my $self = shift;
  __PACKAGE__->new(
    $self->{query}->clone
  );
};


# Bundle the current match
sub current_bundle {
  my $self = shift;

  if (DEBUG) {
    print_log('d_bundle', 'Get bundle');
  };

  return $self->{current_bundle};
};


# TODO:
#   Implement next doc!
sub next_doc {
  ...
};


# Move to next bundle
sub next_bundle {
  my $self = shift;

  # Reset current bundle
  $self->{current_bundle} = undef;

  my $first;

  # There is a bundle on buffer
  if ($self->{buffer}) {


    if (DEBUG) {
      print_log('d_bundle', 'There is a buffered posting for first');
    };

    $first = $self->{buffer};
    $self->{buffer} = undef;
  }

  # Move forward
  elsif ($self->{query}->next) {

    if (DEBUG) {
      print_log('d_bundle', 'Get new posting for first');
    };

    unless ($first = $self->{query}->current) {

      if (DEBUG) {
        print_log('d_bundle', 'There is no more posting');
      };

      return;
    };
  }

  # Can't move forward
  else {

    if (DEBUG) {
      print_log('d_bundle', 'No postings to move forward');
    };

    return;
  };

  my $bundle = Krawfish::Posting::List->new($first);
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

      if (DEBUG) {
        print_log('d_bundle', 'Posting ' . $next->to_string . ' has identical doc id');
      };

      $bundle->add($next);
    }

    # Remember the next bundle
    else {

      if (DEBUG) {
        print_log('d_bundle', 'Posting ' . $next->to_string . ' has different doc id');
      };

      $self->{buffer} = $next;
      last;
    };
  };

  if (DEBUG) {
    print_log('d_bundle', 'Current bundle is ' . $bundle->to_string);
  };

  $self->{current_bundle} = $bundle;
  return 1;
};



# Return the current match
sub current {
  my $self = shift;
  if (DEBUG) {
    print_log('d_bundle', 'Current posting is ' . $self->{current}->to_string);
  };

  $self->{current};
};


# TODO:
#   This is similar to Segment::Sort
# Move to next posting in the current bundle
sub next {
  my $self = shift;

  if (DEBUG) {
    print_log('d_bundle', 'Move to next posting');
  };

  # Get current bundle
  my $bundle = $self->current_bundle;

  if (DEBUG && !$bundle) {
    print_log('d_bundle', 'There is no current bundle');
  };

  # Check next in bundle
  while (!$bundle || !$bundle->next) {

    if (DEBUG) {
      if (!$bundle) {
        print_log('d_bundle', 'Current bundle does not exist yet or there is none');
      }
      else {
        print_log('d_bundle', 'There is no more entry in current bundle');
      };

      print_log('d_bundle', 'Move to next bundle');
    };

    # There are more bundles
    if ($self->next_bundle) {
      $bundle = $self->current_bundle;
      print_log('d_bundle', 'Current bundle to check is ' . $bundle->to_string);
    }

    # There are no more bundles
    else {

      if (DEBUG) {
        print_log('d_bundle', 'No more bundles');
      };

      $self->{current} = undef;
      return 0;
    };
  };


  $self->{current} = $bundle->current;
  return 1;

};

sub to_string {
  'bundleDocs(' . $_[0]->{query}->to_string . ')';
};


1;
