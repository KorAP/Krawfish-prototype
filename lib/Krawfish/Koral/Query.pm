package Krawfish::Koral::Query;
use Krawfish::Koral::Query::Token;
use Krawfish::Koral::Query::Span;
use Krawfish::Koral::Query::Sequence;
use Krawfish::Koral::Query::Position;
use strict;
use warnings;

use constant CONTEXT => 'http://korap.ids-mannheim.de/ns/koral/0.6/context.jsonld';

sub new {
  my $class = shift;
  bless {}, $class;
};

sub index {
  my $self = shift;
  $self->{index} = shift;
};

sub filter_by {
  my $self = shift;
  $self->{filter} = shift;
};

sub seq {
  shift;
  return Krawfish::Koral::Query::Sequence->new(@_);
};

sub token {
  shift;
  return Krawfish::Koral::Query::Token->new(@_);
};

sub token_group {
  shift;
  return Krawfish::Koral::Query::TokenGroup->new(@_);
}


sub span {
  shift;
  return Krawfish::Koral::Query::Span->new(@_);
};

sub position {
  shift;
  return Krawfish::Koral::Query::Position->new(@_);
};

sub to_koral_fragment;


sub from_koral {
  ...
};

sub to_koral_query {
  my $self = shift;
  return {
    '@context' => CONTEXT,
    query => $self->to_koral_fragment
  };
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
