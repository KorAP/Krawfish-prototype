package Krawfish::Koral::Meta;
use parent 'Krawfish::Info';
use Krawfish::Log;
use Krawfish::Result::Sort::PriorityCascade;
use Krawfish::Result::Limit;
use Krawfish::Result::Aggregate;
use Krawfish::Result::Aggregate::Facets;
use strict;
use warnings;

use constant {
  DEBUG => 1,
  UNIQUE_FIELD => 'docID'
};

sub new {
  my $class = shift;
  bless {
    query => undef,
    items_per_page => undef,
    field_sort => [],
    facets => undef,
    start_index => 0
  }, $class;
};

sub search_for {
  my $self = shift;
  $self->{query} = shift;
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


# Contains doc_freq and freq ???
#sub count {
#  $_[0]->{count};
#};

sub prepare_for {
  shift->plan_for(@_);
}

sub plan_for {
  my ($self, $index) = @_;

  # TODO: Should filter over rank!
  my $query = $self->{query} or return;

  # Prepare the nested query
  $query = $query->prepare_for($index);

  # Get the maximum rank for fields, aka the document number
  my $max_doc_rank = $index->max_rank;

  # This is a shared value for faster filtering
  my $max_doc_rank_ref = \$max_doc_rank;

  # TODO:
  #   The dictionary should also have a max_rank!


  my @aggr;
  # Add facets to the result
  if ($self->{facets}) {

    # This should have more parameters, like count
    foreach (@{$self->{facets}}) {
      push @aggr, Krawfish::Result::Aggregate::Facets->new($index, $_);
    };
  };

  # Augment the query with aggregations
  if (@aggr) {
    $query = Krawfish::Result::Aggregate->new($query, \@aggr);
  };

  # Sort the result
  if ($self->{field_sort}) {

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
  };

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
  #     limit(
  #       sorted(
  #         faceted(
  #           count(Q)
  #         )
  #       )
  #     )
  #   )
  # )
  #
  # if ($self->faceted_by) {
  #   $query = Krawfish::Search::FieldFacets->new(
  #      $query,
  #      $index,
  #      $self->faceted_by
  #   );
  # };
  #
  # if ($self->sorted_by) {
  #   Krawfish::Search::FieldSort->new(@{$self->sorted_by});
  # }

  return $query;
};


1;

__END__
