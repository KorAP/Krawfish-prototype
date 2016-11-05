package Krawfish::Koral;
use strict;
use warnings;
use Krawfish::Info;
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

  return $koral;
};


1;

__END__

sub search {
  my $self = shift;
  my $callback = shift;
  my $token = Krawfish::Query::Token->new(
    $self->{index},
    $term
  );

  # Filter the results
  if ($self->filter_by) {

    # Filter the result
    $token->filter_by($self->filter_by);
  };

  # Apply Sorting here

  # Iterate over all matches
  while ($self->next) {

    # Call callback with match
    $callback->($self->current) or return;
  };
};
