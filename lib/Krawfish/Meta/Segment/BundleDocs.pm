package Krawfish::Meta::Segment::BundleDocs;
use parent 'Krawfish::Meta';
use Krawfish::Log;
use Krawfish::Posting::Bundle;
use strict;
use warnings;

# Bundle matches in the same document.

use constant DEBUG => 1;

sub new {
  my $class = shift;
  bless {
    query => shift,
    next_item => undef
  }, $class;
};


# Bundle the current match
sub current_bundle {
  my $self = shift;

  if (DEBUG) {
    print_log('bundle', 'Get bundle');
  };

  return $self->{current_bundle} if $self->{current_bundle};

  my $first = $self->{next_item};

  # Need a next() first
  return unless $first;

  my $bundle = Krawfish::Posting::Bundle->new($first);
  my $query = $self->{query};

  if (DEBUG) {
    print_log('bundle', 'Start bundle with ' . $first->to_string);
  };


  # There is a next entry
  while ($query->next) {
    my $next = $query->current;

    # Documents are identical - bundle
    if ($next->doc_id == $first->doc_id) {
      $bundle->add($next);
    }

    # Remember the next bundle
    else {
      $self->{first} = $next;
      last;
    };
  };

  $self->{current_bundle} = $bundle;

  return $bundle;
};


sub current {
  return $_[0]->{query}->current;
};


sub next {
  my $self = shift;
  $self->{current_bundle} = undef;
  if ($self->{query}->next) {
    $self->{next_item} = $self->{query}->current;
    return 1;
  };
  $self->{next_item} = undef;
  return;
};


sub to_string {
  'bundleDocs(' . $_[0]->{query}->to_string . ')';
};


1;
