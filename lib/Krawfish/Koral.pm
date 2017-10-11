package Krawfish::Koral;
use Role::Tiny::With;
use strict;
use warnings;
with 'Krawfish::Koral::Info';
use Krawfish::Log;
use Krawfish::Koral::Document;
use Krawfish::Koral::Query::Builder;
use Krawfish::Koral::Corpus::Builder;
use Krawfish::Koral::Compile::Builder;
use Krawfish::Koral::Compile;

use constant DEBUG => 0;




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
#   my $mb = $koral->compile_builder;
#   $koral->compile(
#     $mb->aggregate(
#       $mb->a_frequencies,
#       $mb->a_fields('license'),
#       $mb->a_fields('corpus'),
#       $mb->a_length
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
    compile  => undef,  # The compile definitions
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


# Compile part of the Koral object
sub compile {
  my $self = shift;
  if ($_[0]) {
    $self->{compile} = Krawfish::Koral::Compile->new(@_);
    return $self;
  };
  return $self->{compile};
};


# Get the compile builder
sub compile_builder {
  Krawfish::Koral::Compile::Builder->new;
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
# TODO:
#   It should probably return a Koral::* object, that can be send!
sub to_nodes {
  my $self = shift;

  # Optionally pass a node id for replication retrieval
  my $replicant_id = shift;

  # Build a complete query object
  my $query;

  # A virtual corpus and a query is given
  if ($self->corpus && $self->query) {

    # Filter query by corpus
    $query = $self->query_builder->filter_by($self->query, $self->corpus);
  }

  # Only a query is given
  elsif ($self->query) {

    print_log('koral', 'Added live document filter') if DEBUG;

    # Add corpus filter for live documents
    $query = $self->query_builder->filter_by(
      $self->query,
      $self->corpus_builder->anywhere
    );
  }

  # Only a corpus query is given
  else {

    # TODO:
    #   This may have influence on the possible compile object!
    $query = $self->corpus;
  };

  # If request is focused on replication, filter to replicates
  if ($replicant_id) {
    $query = $self->query_builder->filter_by(
      $query,
      $self->corpus_builder->replicant_node($replicant_id)
    );
  }

  # Focus on primary data
  else {
    # $query = $self->query_builder->filter_by(
    #   $query,
    #   $self->corpus_builder->primary_node
    # );
  }

  # Normalize the query
  my $query_norm;
  unless ($query_norm = $query->normalize) {
    $self->copy_info_from($query);
    return;
  };

  # Finalize the query
  my $query_final;
  unless ($query_final = $query_norm->finalize) {
    $self->copy_info_from($query);
    return;
  };

  # This is just for testing
  return $query_final unless $self->compile;

  # Normalize the compile
  my $compile;
  unless ($compile = $self->compile->normalize) {
    $self->copy_info_from($self->compile);
    return;
  };

  # Serialize from compile
  return $self->compile->to_nodes($query_final);
};


# Create a single query tree
sub to_query {
  my $self = shift;

  # Optionally pass a node id for replication retrieval
  my $replicant_id = shift;

  # Build a complete query object
  my $query;
  my $corpus_only = 0;

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
      $self->corpus_builder->anywhere
    );
  }

  # Only a corpus query is given
  else {

    # Remember the query is only a corpus query
    $corpus_only = 1;
    $query = $self->corpus;
  };

  # If request is focused on replication, filter to replicates
  if ($replicant_id) {
    $query = $self->query_builder->filter_by(
      $query,
      $self->corpus_builder->replicant_node($replicant_id)
    );
  }

  # Focus on primary data
  else {
    # $query = $self->query_builder->filter_by(
    #   $query,
    #   $self->corpus_builder->primary_node
    # );
  }

  # Normalize the query
  my $query_norm;
  unless ($query_norm = $query->normalize) {
    $self->copy_info_from($query);
    return;
  };

  # Finalize the query
  my $query_final;
  unless ($query_final = $query_norm->finalize) {
    $self->copy_info_from($query);
    return;
  };

  # This is just for testing
  return $query_final unless $self->compile;

  if ($corpus_only) {
    # TODO:
    #   There is only a corpus query involved,
    #   this may make some compile queries neglectable!
  };

  # Normalize the compile
  my $compile;
  unless ($compile = $self->compile->normalize) {
    $self->copy_info_from($self->compile);
    return;
  };

  # Serialize from compile
  return $self->compile->wrap($query_final);
};


# TODO:
#   This is just temporarily, because results are still a mess!
sub to_segments {
  my ($self, $dict) = @_;
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
  ...
};


# TODO:
#   This is the new entry point!
sub prepare_for_cluster {
  # ->normalize->finalize->refer
  ...
};

sub prepare_for_node {
  # ->identify($dict)
  # WARN! This may require a new normalization, but it should be kept in mind that this
  # also may require double added warnings!
  ...
};

sub prepare_for_segment {
  # ->cache->optimize($segment)
  ...
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

  if ($self->compile) {
    push @list, 'compile=[' . $self->compile->to_string . ']';
  };
  if ($self->corpus) {
    push @list, 'corpus=[' . $self->corpus->to_string . ']';
  };
  if ($self->query) {
    push @list, 'query=[' . $self->query->to_string . ']';
  };

  return join(',', @list);
};



sub to_term_string {
  my $self = shift;
  my $str = '';

  my @list = ();

  if ($self->compile) {
    push @list, 'compile=[' . $self->compile->to_term_string . ']';
  };
  if ($self->corpus) {
    push @list, 'corpus=[' . $self->corpus->to_term_string . ']';
  };
  if ($self->query) {
    push @list, 'query=[' . $self->query->to_term_string . ']';
  };

  return join(',', @list);
};


sub to_id_string {
  my $self = shift;
  my $str = '';

  my @list = ();

  if ($self->compile) {
    push @list, 'compile=[' . $self->compile->to_id_string . ']';
  };
  if ($self->corpus) {
    push @list, 'corpus=[' . $self->corpus->to_id_string . ']';
  };
  if ($self->query) {
    push @list, 'query=[' . $self->query->to_id_string . ']';
  };

  return join(',', @list);
};



1;


__END__
