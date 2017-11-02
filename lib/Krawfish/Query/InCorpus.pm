package Krawfish::Query::InCorpus;
use strict;
use warnings;
use Role::Tiny::With;
use Krawfish::Util::Bits;
use Krawfish::Log;

with 'Krawfish::Query';

# Filter matches occuring in the wrong
# subcorpus. This is helpful in comparable corpora,
# e.g. to compare the usage of "make" in an english subcorpus
# and "machen" in a german subcorpus.

# A different (and probably favorable) approach would be to
# rewrite the filter-corpus to only accept the relevant classes.
# this would require an ability to modify corpora, e.g.
# {1:lang=de}|{2:lang=en}. The problem is, this may not work for, e.g.
# startsWith(<base/s>, inCorpus(1:machen)|inCorpus(2:make)), as this
# won't filter in both operands.
# The problem with prefiltering may well be, that buffer/cache approaches
# to the corpus filter fail.

use constant DEBUG => 0;

# Constructor
sub new {
  my $class = shift;
  my $self = bless {
    span => shift,
    flags => shift,
    current => undef
  }, $class;

  if (DEBUG) {
    print_log(
      'inCorpus',
      'Init query ' . $self->{span}->to_string .
        ' with flags ' . reverse(bitstring($self->{flags})));
  };

  return $self;
};


# Clone query
sub clone {
  my $self = shift;
  __PACKAGE__->new(
    $self->{span}->clone,
    $self->{flags}
  );
};


# Return current posting
sub current {
  $_[0]->{current};
};


# Move to next posting
sub next {
  my $self = shift;

  my $span = $self->{span};

  if (DEBUG) {
    print_log('inCorpus', 'Move to next posting in ' . $span->to_string);
  };

  # Move to next posting
  while ($span->next) {
    my $current = $span->current;

    if (DEBUG) {
      print_log('inCorpus', 'Current posting is ' . $current->to_string);
    };

    # Check flags
    if ($current->flags & $self->{flags}) {
      $self->{current} = $current;

      if (DEBUG) {
        print_log('inCorpus', 'Match found in corpus ' . $self->{flags});
      };
      return 1;
    };
  };

  $self->{current} = undef;
  return;
};


# Get maximum frequency
sub max_freq {
  $_[0]->{span}->max_freq;
};


# Filter query by VC
# See comment above regarding prefiltering
sub filter_by {
  my ($self, $corpus) = @_;
  $self->{span} = $self->{span}->filter_by($corpus);
  return $self;
};

# Requires filter
sub requires_filter {
  1;
};


# Stringification
sub to_string {
  my $self = shift;
  my $str = 'inCorpus(';
  $str .= join(',', flags_to_classes($self->{flags})) . ':';
  $str .= $self->{span}->to_string . ')';
  return $str;
};

1;
