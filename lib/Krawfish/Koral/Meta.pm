package Krawfish::Koral::Meta;
use Krawfish::Koral::Meta::SortFilter;
use Krawfish::Koral::Meta::Builder;
use Krawfish::Log;
use strict;
use warnings;

our %META_ORDER = (
  snippet   => 1,
  fields    => 2,
  sort      => 3,
  aggregate => 4,
  filter    => 5
);

use constant {
  DEBUG => 0,
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

  # Add unique sorting per default
  push @meta,
    $mb->sort_by($mb->s_field(UNIQUE_FIELD));

  # 1. Introduce required information
  #    e.g. sort(field) => fields(field)
  my $aggregation = 0;
  for (my $i = 0; $i < @meta; $i++) {

    # For all sort fields, it may be beneficial to
    # retrieve the fields as well - as they need
    # to be retrieved nonetheless for search criteria
    if ($meta[$i]->type eq 'sort') {
      push @meta,
        $self->builder->fields($meta[$i]->fields);
    }

    # There is at least one aggregation field
    elsif ($meta[$i]->type eq 'aggregate') {
      $aggregation = 1;
    }

    # Remove any given sortfilter
    elsif ($meta[$i]->type eq 'sortFilter') {
      splice @meta, $i, 1;
      $i--;
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
      if ($meta[$i]->type eq 'fields' ||
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
  #    No aggregation queries =>
  #      add a sort filter at the end
  unless ($aggregation) {
    push @meta, Krawfish::Koral::Meta::SortFilter->new;
  };

  # Set operations
  $self->operations(@meta);

  return $self;
};

# Create a Krawfish::Result::Meta::Node::* query
sub to_nodes {
  my ($self, $query) = @_;

  # TODO:
  #   Don't forget the warnings etc.

  # The meta query is expected to be normalized
  foreach (reverse $self->operands) {
    $query = $_->to_nodes($query);
  };
};


sub optimize;

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
