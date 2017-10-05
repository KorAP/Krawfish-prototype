package Krawfish::Meta::Segment::BundleDocs;
use parent 'Krawfish::Meta::Segment::Bundle';
use Krawfish::Log;
use Krawfish::Posting::DocBundle;
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
    $first = $self->{buffer};
    $self->{buffer} = undef;
  }

  # Move forward
  elsif ($self->{query}->next) {
    $first = $self->{query}->current or return;
  }

  # Can't move forward
  else {
    return;
  };

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
  return 1;
};


sub to_string {
  'bundleDocs(' . $_[0]->{query}->to_string . ')';
};


1;
