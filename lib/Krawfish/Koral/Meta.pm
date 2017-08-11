package Krawfish::Koral::Meta;
use Krawfish::Koral::Meta::Builder;
use Krawfish::Log;
use strict;
use warnings;

# WARNING! / TODO!
#   An enrichment for fields or snippets (better any enrichments)
#   can never wrap around a sort query, because the relevant
#   data structures and algorithms require the results to be in doc_id order!

# TODO:
#   When a group filter is added,
#   sorting does not work etc.
#   This has to be thought through


our %META_ORDER = (
  #  snippet   => 1,
  #  fields    => 2,
  limit     => 1,
  sort      => 2,
  enrich    => 3,
  aggregate => 4,
  group     => 5,
  filter    => 6
);

use constant {
  DEBUG => 1,
  UNIQUE_FIELD => 'id'
};

sub new {
  my $class = shift;
  bless [@_], $class;
};

sub to_string {
  my $self = shift;
  return join(',', map { $_->to_string } $self->operations);
};


sub builder {
  return Krawfish::Koral::Meta::Builder->new;
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


# Normalize meta object
sub normalize {
  my $self = shift;

  my @meta = $self->operations;

  my $mb = $self->builder;

  # Check, if the query is a group query,
  # which invalidates some meta operations
  my $group_query = 0;
  my $top_k = 0;
  foreach (@meta) {
    if ($_->type eq 'group') {
      $group_query = 1;
    }
    elsif ($_->type eq 'limit') {
      $top_k = $_->start_index + $_->items_per_page;
    };
  };

  # Add unique sorting per default - unless it's a group query
  #unless ($group_query) {
  #  push @meta,
  #    $mb->sort_by($mb->s_field(UNIQUE_FIELD));
  #
  #  if (DEBUG) {
  #    print_log('kq_meta', 'Added unique field ' . UNIQUE_FIELD . ' to order');
  #  };
  #};


  # 1. Introduce required information
  #    e.g. sort(field) => fields(field)
  my $sort_filtering = 1;
  for (my $i = 0; $i < scalar @meta; $i++) {

    # For all sort fields, it may be beneficial to
    # retrieve the fields as well - as they need
    # to be retrieved nonetheless for search criteria
    #if ($meta[$i]->type eq 'sort') {
    #
    #  my $mb = $self->builder;
    #  push @meta,
    #    $mb->enrich($mb->e_fields($meta[$i]->fields));
    #
    #  if (DEBUG) {
    #    print_log('kq_meta', 'Added sorting ' .
    #                join(',', map {$_->to_string } $meta[$i]->fields) .
    #                ' to fields');
    #  };
    #}

    # There is at least one aggregation field
    #els
    if ($meta[$i]->type eq 'aggregate') {
      $sort_filtering = 0;
    }

    # There is at least one group option
    elsif ($meta[$i]->type eq 'group') {
      $sort_filtering = 0;
    };
  };

  # Sort objects based on a defined order
  @meta = sort {
    $META_ORDER{$a->type} <=> $META_ORDER{$b->type}
  } @meta;


  # 2. Find identical types and merge
  #    fields+fields => fields
  #    sort+sort => sort ...
  #    and take the first value for single values
  #    start_index=0 + start_index=2 => start_index=0
  #
  # 3. Remove duplicates
  #    aggr_freq + aggr_freq => - aggr_freq
  for (my $i = 1; $i < @meta; $i++) {

    # Consecutive types are identical, join
    if ($meta[$i]->type eq $meta[$i-1]->type) {

      # Join fields or aggregations
      if ($meta[$i]->type eq 'enrich' ||
            $meta[$i]->type eq 'aggregate' ||
            $meta[$i]->type eq 'sort'
          ) {

        # The first operations have higher precedence
        $meta[$i-1]->operations(
          $meta[$i-1]->operations,
          $meta[$i]->operations
        );

        # Remove merged object
        splice(@meta, $i, 1);
        $i--;
      }

      # TODO:
      #   Make single field values work
      #   - start_index
      #   - count

      # Unknown operation
      else {
        warn 'Unable to deal with unknown meta operation' . $meta[$i]->type;
      };

      # Don't normalize nonmerged data
      next;
    };

    # Normalize when no longer consecutive operations
    # can be expected
    $meta[$i-1] = $meta[$i-1]->normalize;
  };

  # Normalize last operation
  $meta[-1] = $meta[-1]->normalize;

  # 4. Optimize
  #    No aggregation or group queries =>
  #      add a sort filter to sort
  #    If a limit is given, add top_k to sort
  if ($sort_filtering || $top_k) {
    foreach (@meta) {
      if ($_->type eq 'sort') {

        # Activate sort_filter option
        $_->filter(1) if $sort_filtering;

        # Set top_k option!
        $_->top_k($top_k) if $top_k;
        last;
      };
    };
  };

  # Set operations
  $self->operations(@meta);

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


sub to_segment {
  ...
};


sub optimize {
  ...
};

1;


__END__


sub items_per_page {
  my $self = shift;
  return $self->{items_per_page} unless @_;
  $self->{items_per_page} = shift;
  return $self;
};


sub start_index {
  my $self = shift;
  return $self->{start_index} unless @_;
  $self->{start_index} = shift;
  return $self;
};


sub facets {
  my $self = shift;
  return $self->{facets} unless @_;
  $self->{facets} = [@_];
  return $self;
};


# Count doc_freq and freq
sub count {
  my $self = shift;
  return $self->{count} unless @_;
  $self->{count} = shift;
  return $self;
};


# Get lengths of results
sub length {
  my $self = shift;
  return $self->{length} unless @_;
  $self->{length} = shift;
  return $self;
};


sub prepare_for {
  shift->plan_for(@_);
};


# Check if the meta query is filterable
sub sort_filter {
  my ($self, $query, $index) = @_;

  # No sort defined
  return $query unless $self->{field_sort};

  # Sort is not restricted
  return $query unless $self->{items_per_page};

  # Filtering not applicable because
  # all matches need to be found
  if ($self->{facets} ||
        $self->{field_count} ||
        $self->{count} ||
        $self->{length}) {
    return $query;
  };

  # Get first run field
  my ($field, $desc) = @{$self->{field_sort}->[0]};

  # Create rank filter
  $query = Krawfish::Result::Sort::Filter->new(
    query        => $query,
    max_rank_ref => $self->max_doc_rank_ref,
    field        => $field,
    desc         => $desc,
    index        => $index
  );

  print_log('kq_meta', 'Query is qualified for sort filtering') if DEBUG;

  return $query;
};


# Return max_doc_rank reference
sub max_doc_rank_ref {
  my $self = shift;

  # Set value to reference
  ${$self->{max_doc_rank_ref}} = shift if @_;

  return $self->{max_doc_rank_ref};
};


sub plan_for {
  my ($self, $index) = @_;

  # Get the query
  my $query = $self->{query} or return;


  # TODO:
  #   The dictionary should also have a max_rank!


  # Get the maximum rank for fields, aka the document number
  # and init the shared value for faster filtering
  my $max_doc_rank_ref = $self->max_doc_rank_ref($index->max_rank);

  # Prepare the nested query
  $query = $query->prepare_for($index);

  my @aggr;
  # Add facets to the result
  if ($self->{facets}) {

    # This should have more parameters, like count
    foreach (@{$self->{facets}}) {
      push @aggr, Krawfish::Result::Segment::Aggregate::Facets->new($index, $_);
    };
  };

  # Count field values
  if ($self->{field_count}) {

    # This should have more parameters, like count
    foreach (@{$self->{field_count}}) {
      push @aggr, Krawfish::Result::Segment::Aggregate::Values->new($index, $_);
    };
  };

  # Add frequency and document frequency count to result
  # TODO:
  #   This may be obsolete in some cases, because other aggregations already
  #   count frequencies.
  if ($self->{count}) {
    push @aggr, Krawfish::Result::Segment::Aggregate::Frequencies->new;
  };

  if ($self->{length}) {
    push @aggr, Krawfish::Result::Segment::Aggregate::Length->new;
  };

  # Augment the query with aggregations
  # TODO:
  #   It may be better to have one aggregation object, that can be filled!
  #   like ->query($query)->aggregate_on($aggr)->prepare_for($index);
  #   and after the query is through, the aggregation map contains data
  if (@aggr) {
    $query = Krawfish::Result::Segment::Aggregate->new($query, \@aggr);
  };

  # Sort the result
  # This is mandatory!

  # Precalculate top_k value
  my $top_k = undef;
  if ($self->items_per_page) {

    # Top k is defined
    $top_k = $self->items_per_page + ($self->start_index // 0);
  };

  # TODO:
  #   Check for fields that are either not part
  #   of the index or are identified in
  #   the corpus query (it makes no sense to
  #   sort for author, if author=Fontane is
  #   required)
  $query = Krawfish::Result::Sort::PriorityCascade->new(
    query => $query,
    index => $index,
    fields => $self->{field_sort},
    unique => UNIQUE_FIELD,
    top_k => $top_k,
    max_rank_ref => $max_doc_rank_ref
  );

  print_log('kq_meta', "Field sort with: " . $query->to_string) if DEBUG;


  # Limit the result
  if ($self->items_per_page || $self->start_index) {
    $query = Krawfish::Result::Limit->new(
      $query,
      $self->start_index,
      $self->items_per_page
    );
  };

  # The order needs to be:
  # snippet(
  #   fields(
  #     limit( -
  #       sorted( -
  #         faceted( -
  #           count(Q) -
  #         )
  #       )
  #     )
  #   )
  # )

  # Return the query
  return $query;
};


1;

__END__
