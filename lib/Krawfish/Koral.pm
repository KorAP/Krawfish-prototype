package Krawfish::Koral;
use parent 'Krawfish::Info';
use strict;
use warnings;
use Krawfish::Koral::Query;
use Krawfish::Koral::Query::Builder;
use Krawfish::Koral::Corpus;
use Krawfish::Koral::Corpus::Builder;
use Krawfish::Koral::Meta;
use Krawfish::Koral::Document;

# TODO:
# Krawfish::Koral::Query
# Krawfish::Koral::Corpus
# Krawfish::Koral::Meta

# TODO:
#   Filtering needs to be supported multiple times,
#   so when one filter is applied (virtual corpus),
#   another one can be filtered before (bin-sorting).

use constant CONTEXT => 'http://korap.ids-mannheim.de/ns/koral/0.6/context.jsonld';

sub new {
  my $class = shift;
  my $self = bless {
    query  => undef,
    corpus => undef,
    meta   => undef,
    document => undef
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

sub query {
  my $self = shift;
  $self->{query} = shift if $_[0];
  return $self->{query};
};

sub query_builder {
  Krawfish::Koral::Query::Builder->new;
};

sub corpus {
  my $self = shift;
  $self->{corpus} = shift if $_[0];
  return $self->{corpus};
};

sub corpus_builder {
  Krawfish::Koral::Corpus::Builder->new;
};

sub meta { ... };

# sub response { ... };

sub from_koral_query {
};

# Serialization of KoralQuery
sub to_koral_query {
  my $self = shift;

  my $koral = {
    '@context' => CONTEXT
  };

  if ($self->query) {
    $koral->{'query'} = $self->query->to_koral_fragment
  };

  if ($self->corpus) {
    $koral->{'corpus'} = $self->corpus->to_koral_fragment
  };

  $self->merge_info($koral);

  return $koral;
};


# Prepare the query for index
sub prepare_for {
  my ($self, $index) = @_;

  my $query;

  # Corpus and query are given - filter!
  if ($self->corpus && $self->query) {

    $query = $self->query->filter_by($self->corpus);
  }

  # Only corpus is given
  elsif ($self->corpus) {
    $query = $self->corpus;
  }

  # Only query is given
  elsif ($self->query) {
    $query = $self->query;
  };

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

  if ($self->corpus && $self->query) {
    $str .= 'filterBy(';
    $str .= $self->query->to_string;
    $str .= ',';
    $str .= $self->corpus->to_string;
    $str .= ')';
  }
  elsif ($self->corpus) {
    $str .= $self->corpus->to_string;
  }
  elsif ($self->query) {
    $str .= $self->query;
  };

  return $str;
};

1;

__END__

