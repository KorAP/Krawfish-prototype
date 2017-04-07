package Krawfish::Koral::Meta;
use parent 'Krawfish::Info';
use Krawfish::Log;
use Krawfish::Result::Sort::Filter;
use Krawfish::Result::Sort::PriorityCascade;
use Krawfish::Result::Limit;
use Krawfish::Result::Aggregate;
use Krawfish::Result::Aggregate::Facets;
use Krawfish::Result::Aggregate::Count;
use Krawfish::Result::Aggregate::Length;
use Krawfish::Result::Aggregate::Values;
use strict;
use warnings;

use constant {
  DEBUG => 1,
  UNIQUE_FIELD => 'id'
};

sub new {
  my $class = shift;
  bless {
    query => undef,
    items_per_page => undef,
    field_sort => [],
    field_count => undef,
    facets => undef,
    count => undef,
    start_index => 0,
    max_doc_rank_ref => \(my $init = 0)
  }, $class;
};

# Nest the query
sub search_for {
  my ($self, $query) = @_;
  $self->{query} = $query;
  return $self;
};

#sub fields;

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
      push @aggr, Krawfish::Result::Aggregate::Facets->new($index, $_);
    };
  };

  # Count field values
  if ($self->{field_count}) {

    # This should have more parameters, like count
    foreach (@{$self->{field_count}}) {
      push @aggr, Krawfish::Result::Aggregate::Values->new($index, $_);
    };
  };

  # Add frequency and document frequency count to result
  # TODO:
  #   This may be obsolete in some cases, because other aggregations already
  #   count frequencies.
  if ($self->{count}) {
    push @aggr, Krawfish::Result::Aggregate::Count->new;
  };

  if ($self->{length}) {
    push @aggr, Krawfish::Result::Aggregate::Length->new;
  };

  # Augment the query with aggregations
  # TODO:
  #   It may be better to have one aggregation object, that can be filled!
  #   like ->query($query)->aggregate_on($aggr)->prepare_for($index);
  #   and after the query is through, the aggregation map contains data
  if (@aggr) {
    $query = Krawfish::Result::Aggregate->new($query, \@aggr);
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
