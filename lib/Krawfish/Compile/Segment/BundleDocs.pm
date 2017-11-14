package Krawfish::Compile::Segment::BundleDocs;
use Krawfish::Log;
use Krawfish::Posting::List;
use strict;
use warnings;
use Role::Tiny;

with 'Krawfish::Compile::Segment::Bundle';
with 'Krawfish::Compile';

requires qw/next_bundle/;


# Bundle matches in the same document.

# TODO:
#   The problem with the current approch is, that next_bundle
#   will bundle the next doc - without asking if the doc
#   is relevant.
#   That's why next_doc is identical to next_bundle-

use constant DEBUG => 0;

sub new {
  my $class = shift;
  bless {
    query => shift,
    buffer => undef
  }, $class;
};


# Clone query
sub clone {
  my $self = shift;
  __PACKAGE__->new(
    $self->{query}->clone
  );
};


# Move to next doc
sub next_doc {
  return $_[0]->next_bundle;
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


# Stringification
sub to_string {
  'bundleDocs(' . $_[0]->{query}->to_string . ')';
};


1;
