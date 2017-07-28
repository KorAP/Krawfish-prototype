package Krawfish::Koral;
use parent 'Krawfish::Info';
use strict;
use warnings;
use Krawfish::Koral::Query::Builder;
use Krawfish::Koral::Corpus::Builder;
use Krawfish::Koral::Meta::Builder;
use Krawfish::Koral::Meta;
use Krawfish::Koral::Document;

# Parse a koral query and transform to an actual
# index query.
#
# Procession order for query and corpus:
#   a) parse                            (cluster)
#   b) normalize and finalize           (cluster)
#   c) refer (no multiple leaf lifting) (cluster) (or not)
#   d) inflate (some normalization)     (node)
#   e) memoize                          (segment)
#   f) optimize                         (segment)
#
# Usage:
#   $koral = Koral->new;
#   my $qb = $koral->query_builder;
#   my $cb = $koral->corpus_builder;
#   my $mb = $koral->meta_builder;
#   $koral->meta(
#     $mb->aggregate(
#       $mb->aggr_frequencies,
#       $mb->aggr_facets('license'),
#       $mb->aggr_facets('corpus'),
#       $mb->aggr_length
#     )->start_index(0)
#     ->items_per_page(20)
#     ->sort_by(
#       $mb->sort_field('author', 1)
#     )->fields('author')
#     ->snippet('')
#   )->query(
#     $qb->token('aa')
#   )->corpus(
#     $cb->string('xx')
#   );
#
#   $koral->to_cluster ... ->to_node($dict) ... ->to_segment($index)

# TODO:
#   Filtering needs to be supported multiple times,
#   so when one filter is applied (virtual corpus),
#   another one can be filtered before (bin-sorting).

# TODO:
#   When a user searches a term in a query,
#   this should issue an update in the autosuggestion
#   dictionary.

# TODO:
#   This is now double with Krawfish::Koral::Query!
use constant {
  CONTEXT => 'http://korap.ids-mannheim.de/ns/koral/0.6/context.jsonld'
};

sub new {
  my $class = shift;
  my $self = bless {
    query    => undef,  # The query definition
    corpus   => undef,  # The vc definition
    matches  => undef,  # List of match IDs
    meta     => undef,  # The meta definitions
    document => undef,  # Document data to import
    response => undef   # Response object
  }, $class;

  return $self unless @_;

  # Expect a hash
  my $koral = shift;

  # Import document
  if ($koral->{document}) {
    $self->{document} = Krawfish::Koral::Document->new($koral->{document});
  };

  return $self;
};


# Query part of the Koral object
sub query {
  my $self = shift;
  if ($_[0]) {
    $self->{query} = shift;
    return $self;
  };
  return $self->{query};
};


# Get the query builder
sub query_builder {
  Krawfish::Koral::Query::Builder->new;
};


# Corpus part of the Koral object
sub corpus {
  my $self = shift;
  if ($_[0]) {
    $self->{corpus} = shift;
    return $self;
  };
  return $self->{corpus};
};


# Get the corpus builder
sub corpus_builder {
  Krawfish::Koral::Corpus::Builder->new;
};


# Meta part of the Koral object
sub meta {
  my $self = shift;
  if ($_[0]) {
    $self->{meta} = Krawfish::Koral::Meta->new(@_);
    return $self;
  };
  return $self->{meta};
};


# Get the meta builder
sub meta_builder {
  Krawfish::Koral::Meta::Builder->new;
};


# sub response { ... };

sub from_koral_query {
  ...
};


# Clone the query object
sub clone {
  ...
};

# This introduces the normalization phase
sub to_nodes {
  my $self = shift;

  # Build a complete query object
  my $query;

  # A virtual corpus and a query is given
  if ($self->corpus && $self->query) {

    # Filter query by corpus
    $query = $self->query_builder->filter_by($self->query, $self->corpus);
  }

  # Only a query is given
  elsif ($self->query) {

    # Add corpus filter for live documents
    $query = $self->query_builder->filter_by(
      $self->query,
      $self->corpus_builder->any
    );
  }

  # Only a corpus query is given
  else {

    # TODO:
    #   This may have influence on the possible meta object!
    $query = $self->corpus;
  };

  # Normalize the query
  my $query_norm;
  unless ($query_norm = $query->normalize) {
    $self->copy_info_from($query);
    return;
  };

  # Finalize the query
  my $query_final;
  unless ($query_final = $query_norm->normalize) {
    $self->copy_info_from($query);
    return;
  };

  # This is just for testing
  return $query_final unless $self->meta;

  # Normalize the meta
  my $meta;
  unless ($meta = $self->meta->normalize) {
    $self->copy_info_from($self->meta);
    return;
  };

  # Serialize from meta
  return $self->meta->to_nodes($query_final);
};





# Serialization of KoralQuery
sub to_koral_query {
  my $self = shift;

  my $koral = {
    '@context' => CONTEXT
  };

  # Set query object
  if ($self->query) {
    $koral->{query} = $self->query->to_koral_fragment
  };

  # Set corpus object
  if ($self->corpus) {
    $koral->{corpus} = $self->corpus->to_koral_fragment
  };

  $self->merge_info($koral);

  return $koral;
};







# Get KoralQuery with results
sub to_result {
  my ($self, $index) = @_;

  warn 'THIS HAS TO BE DONE DIFFERENTLY';

  # Get KoralQuery object
  my $koral = $self->to_koral_query;

  # Prepare query
  my $query = $self->prepare_for($index);

  # TODO:
  #   This is only for matches - not for groups
  while ($query->next) {

    # Add matches to koral
    $koral->add_match(

      # Get current match
      $query->current_match
    )
  };

  # Get result hash (e.g. totalResults)
  $koral->{result} = $query->result;
};



# TODO:
#   This is the new entry point!
sub prepare_for_cluster {
  # ->normalize->finalize->refer
  ...
};

sub prepare_for_node {
  # ->inflate($dict)
  # WARN! This may require a new normalization, but it should be kept in mind that this
  # also may require double added warnings!
  ...
};

sub prepare_for_segment {
  # ->cache->optimize($index)
  ...
};


# Prepare the query for index
sub prepare_for {
  my ($self, $index) = @_;

  my $query;

  # Corpus and query are given - filter!
  if ($self->query && $self->corpus) {

    my $corpus = $self->corpus;

    # Meta is defined
    if ($self->meta) {

      # Wrap in sort filter if available
      $corpus = $self->meta->sort_filter($corpus);
    };

    # Add corpus filter
    $query = $self->query_builder->filter_by($self->query, $self->corpus);
  }

  # Only corpus is given
  elsif ($self->corpus) {
    $query = $self->corpus;

    # Wrap in sort filter if available
    $query = $self->meta->sort_filter($query, $index) if $self->meta;
  }

  # Only query is given
  elsif ($self->query) {
    $query = $self->query;

    # TODO:
    #   Somehow do sort_filtering here with a corpus based
    #   on non-deleted documents or so.
  };

  # If meta is defined, prepare results
  $query = $self->meta->search_for($query) if $self->meta;

  # TODO:
  # The following operations will invalidate sort filtering:
  # - grouping
  # - aggregate (except result is already cached)

  # TODO:
  # if ($self->sorting && $self->sorting->filter) {
  #   # Filter matches using a sort filter
  #   $query = $self->query->filter_by($self->sorting->filter);
  # };

  # TODO:
  #  - Find identical subqueries
  #  - This is especially useful for VC filtering,
  #  - Terms (PostingsList) will automatically avoid
  #    lifting posting lists multiple times.
  #
  # That means: create a buffered version of $self->corpus
  #
  # TODO: Make this part of ->plan_for($index, $refs)
  #
  # $query->replace_references;


  # Prepare query
  $query = $query->prepare_for($index);
  # $query = $query->normalize->finalize->inflate($index->dict)->optimize($index);

  return $query;
};


# Find identical subqueries and replace outer queries with
# - references or
# - cached queries
sub replace_subqueries {
  my ($self, $query) = @_;

  # The reference store will collect signatures of subqueries
  # To replace identical subqueries with reference pointers
  my $refs = {};

  # TODO: Load real cache!
  # The cache is global and will replace subqueries that are
  # already cached
  my $cache = Krawfish::Cache->new;
  $query->replace_subqueries($refs, $cache);

  return $query;
};


sub to_string {
  my $self = shift;
  my $str = '';

  my @list = ();

  if ($self->meta) {
    push @list, 'meta=[' . $self->meta->to_string . ']';
  };
  if ($self->corpus) {
    push @list, 'corpus=[' . $self->corpus->to_string . ']';
  };
  if ($self->query) {
    push @list, 'query=[' . $self->query->to_string . ']';
  };

  return join(',', @list);
};

1;

__END__



sub sorting {
  ...
};


# Normalize object
sub normalize {
  my $self = shift;

  my $query;

  # Corpus and query are given - filter!
  if ($self->query && $self->corpus) {

    my $corpus = $self->corpus;

    # Add corpus filter
    $query = $self->query_builder->filter_by($self->query, $self->corpus);

    # Meta is defined
    if ($self->meta) {

      # TODO: Make this a filter query!

      # Wrap in sort filter if available
      $corpus = $self->meta->sort_filter($corpus);
    };
  }

  # Only corpus is given
  elsif ($self->corpus) {
    $query = $self->corpus;

    # Wrap in sort filter if available

    # TODO:
    # $query = $self->meta->sort_filter($query, $index) if $self->meta;
  }

  # Only query is given
  elsif ($self->query) {

    # Add corpus filter for live documents
    $query = $self->query_builder->filter_by(
      $self->query,
      $self->corpus_builder->any
    );
  };


  # If meta is defined, prepare results
  if ($self->meta) {
    $query = $self->meta->search_for($query);
  };


  # Prepare query
  return $query->normalize;
};
