package Krawfish::Koral::Compile;
use Krawfish::Koral::Compile::Builder;
use Krawfish::Log;
use strict;
use warnings;

# Creation of compilation query

# WARNING! / TODO!
#   An enrichment for fields or snippets (better any enrichments)
#   can never wrap around a presort query, because the relevant
#   data structures and algorithms require the results to be in
#   doc_id order!

# WARNING!
#   It's important to remember that sortFilter can't be shared in parallel
#   processing - especially for fields, as segment rankings can differ!

# TODO:
#   There are presort and postsort queries.
#   Presortqueries don't respect current_query,
#   while postsortqueries do!
#   Postsortqueries only work on the clusterlevel.

# TODO:
#   When a group filter is added,
#   sorting does not work etc.
#   This has to be thought through

# TODO:
#   Remove corpus classes, in case they are not used.
#   This requires a method like ->used_classes

# TODO:
#   Support aggregations on groups!

our %COMPILE_ORDER = (
  limit           => 1,
  cluster_merge   => 2,
  node_merge      => 3,
  sort            => 4,
  sample          => 5,
  enrich          => 6,
  group_aggregate => 7,
  group           => 8,
  aggregate       => 9,
  filter          => 10
);


use constant DEBUG => 0;


# Constructor
sub new {
  my $class = shift;
  bless [@_], $class;
};


# Stringification
sub to_string {
  my ($self, $id) = @_;
  return join(',', map { $_->to_string($id) } $self->operations);
};


# Get builder object
sub builder {
  return Krawfish::Koral::Compile::Builder->new;
};


# Get or set operations
sub operations {
  my $self = shift;
  if (@_) {
    @$self = @_;
    return $self;
  };
  return @$self;
};


# Add operation
sub add {
  my ($self, $op) = @_;
  push @$self, $op;
};


# Normalize compile object
sub normalize {
  my $self = shift;

  my @compile = $self->operations;

  my $mb = $self->builder;

  # Check, if the query is a group query,
  # which invalidates some compile operations
  my $group_query = 0;
  my $top_k = 0;
  foreach (@compile) {
    if ($_->type eq 'group') {
      $group_query = 1;
    }
    elsif ($_->type eq 'limit') {
      $top_k = $_->start_index + $_->items_per_page;
    };
  };

  # Add unique sorting per default - unless it's a group query
  # unless ($group_query) {
  #   push @compile,
  #     $mb->sort_by($mb->s_field(UNIQUE_FIELD));
  #
  #   if (DEBUG) {
  #     print_log('kq_compile', 'Added unique field ' . UNIQUE_FIELD . ' to order');
  #   };
  # };


  # 1. Introduce required information
  my $sort_filtering = 1;
  for (my $i = 0; $i < scalar @compile; $i++) {

    # There is at least one aggregation field
    if ($compile[$i]->type eq 'aggregate') {
      $sort_filtering = 0;
    }

    # There is at least one group option
    elsif ($compile[$i]->type eq 'group') {
      $sort_filtering = 0;
    };
  };

  # Sort objects based on a defined order
  @compile = sort {
    $COMPILE_ORDER{$a->type} <=> $COMPILE_ORDER{$b->type}
  } @compile;


  # 2. Find identical types and merge
  #    fields+fields => fields
  #    sort+sort => sort ...
  #    and take the first value for single values
  #    start_index=0 + start_index=2 => start_index=0
  #
  for (my $i = 1; $i < @compile; $i++) {

    # 3. Remove duplicates
    #    aggr_freq + aggr_freq => - aggr_freq
    # Consecutive types are identical, join
    if ($compile[$i]->type eq $compile[$i-1]->type) {

      # Join fields or aggregations
      if ($compile[$i]->type eq 'enrich' ||
            $compile[$i]->type eq 'sort' ||
            $compile[$i]->type eq 'aggregate' ||
            $compile[$i]->type eq 'group_aggregate'
          ) {

        # The first operations have higher precedence
        $compile[$i-1]->operations(
          $compile[$i-1]->operations,
          $compile[$i]->operations
        );

        # Remove merged object
        splice(@compile, $i, 1);
        $i--;
      }

      # TODO:
      #   Make single field values work
      #   - start_index
      #   - count

      # Unknown operation
      else {
        warn 'Unable to deal with unknown compile operation' . $compile[$i]->type;
      };

      # Don't normalize nonmerged data
      CORE::next;
    };

    # Normalize when no longer consecutive operations
    # can be expected
    $compile[$i-1] = $compile[$i-1]->normalize;
  };

  # Normalize last operation
  $compile[-1] = $compile[-1]->normalize;

  # 4. Optimize
  #    No aggregation or group queries =>
  #      add a sort filter to sort
  #    If a limit is given, add top_k to sort
  if ($sort_filtering && $top_k) {
    foreach (@compile) {
      if ($_->type eq 'sort') {

        # Activate sort_filter option
        $_->filter(1); # if $sort_filtering;

        # Set top_k option!
        $_->top_k($top_k) if $top_k;
        last;
      }

      elsif ($_->type eq 'sample') {
        # Set top_k option!
        $_->top_k($top_k) if $top_k;
        last;
      };
    };
  };

  # Set operations
  $self->operations(@compile);

  return $self;
};


# Translate all fields to term ids
sub identify {
  my ($self, $dict) = @_;

  for (my $i = 0; $i < @$self; $i++) {
    $self->[$i] = $self->[$i]->identify($dict);
  };

  return $self;
};


# Wrap operations in a single query object
sub wrap {
  my ($self, $query) = @_;
  foreach (reverse $self->operations) {
    $query = $_->wrap($query);
  };
  return $query;
};


1;


__END__
