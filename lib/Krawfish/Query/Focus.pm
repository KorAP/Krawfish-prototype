package Krawfish::Query::Focus;
use strict;
use warnings;
use Role::Tiny::With;

# Maybe
#   use Krawfish::Query::Base::Sorted;


with 'Krawfish::Query';

# See 
# See 

# The focus query can focus on a specific part of the
# subquery, that may be in the span of the subquery
# or outside (when focussing in a query that was already
# focussed).
#
# This can cause several problems regarding sorting:
# a) The span `<a>...{1:...}...</a>` is modified using
#    `focus(1:...)`. A following span `<a>{1:...}...</a>`
#    has the class 1 in a preceding position.
# b) The span `<a>...{1:...}...{2:...}...</a>` is modified
#    using `focus(2:...)`, but still contains a class 1.
#    Now, if the span is again modified using `focus(1:...)`
#    a preceding match span may be `<a>...{2:...}...{1:...}...</a>`,
#    so the second class 1 may precede the first class 1.
#
# This requires all focus spans to be sort-buffered, in case
# the subquery is maybe_unsorted.
# Because the wrapping query is guaranteed to be sorted,
# when it moves forward, all spans in the priority queue
# with start position smaller than the new start position
# of the longest subspan can be released.
# To guarantee sorted focus spans, the focus query keeps
# track of the largest possible span (by adding a payload
# with a fixed class number > 128 including minimal start
# and maximum end position),
# and taking this into account (in case it's set) instead
# of only the current wrapped query length
# (see https://github.com/KorAP/Krill/issues/7)
# when comparing with the highest priority matches.
# (see https://github.com/KorAP/Krill/issues/48)

sub new {
  my $class = shift;
  bless {
    span => shift,
    nrs => shift,
    sorted => shift // 0
  }, $class;
};


# Clone query
sub clone {
  my $self = shift;
  __PACKAGE__->new(
    $self->{span}->clone,
    [@{$self->{nrs}}],
    $self->{sorted}
  );
};

# Move to next focus
sub next {
  my $self = shift;
  ...

    if ($self->{sorted}) {
      # a) If (BUFFER > 0 && $self->{release_buffer}) {
      #      return next from BUFFER
      #    };
      #
      # b) Check if the payload has a longest subquery class span.
      # c) Unionize this with the subquery span.
      #    This is called: LONGEST
      # d) Add LONGEST to payload.
      # e) Add to buffer

      # f) If (BUFFER.start < LONGEST.start) {
      #      $self->{release_buffer};
      #      return next from BUFFER
      #    }
      #
      # g) GOTO a)
    };
  }

  # Requires no sorting
  else {
    # Return the span directly from the
    # posting by analyzing the payload
  };
};


# Get maximum frequency
sub max_freq {
  $_[0]->{span}->max_freq;
};


# Stringification
sub to_string {
  my $self = shift;
  my $str .= 'focus(';
  $str .= join ',', @{$self->{nrs}};
  $str .= ':';
  $str .= 'sorted:' if $self->{sorted};
  $str .= $self->{span}->to_string;
  return $str . ')';
};


# Filter query by VC
sub filter_by {
  my ($self, $corpus) = @_;
  $self->{span} = $self->{span}->filter_by($corpus);
  return $self;
};


# Requires filtering
sub requires_filter {
  return $_[0]->{span}->requires_filter;
};


1;
