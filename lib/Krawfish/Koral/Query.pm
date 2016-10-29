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

#########################
# KoralQuery constructs #
#########################

# Sequence construct
sub seq {
  shift;
  return Krawfish::Koral::Query::Sequence->new(@_);
};


# Token construct
sub token {
  shift;
  return Krawfish::Koral::Query::Token->new(@_);
};


# TokenGroup construct
sub token_group {
  shift;
  return Krawfish::Koral::Query::TokenGroup->new(@_);
};


# Span construct
sub span {
  shift;
  return Krawfish::Koral::Query::Span->new(@_);
};


# Position construct
sub position {
  shift;
  return Krawfish::Koral::Query::Position->new(@_);
};


##########################
# Query Planning methods #
##########################

sub is_any            { ... };
sub is_optional       { ... };
sub is_null           { ... };
sub is_negative       { ... };
sub is_extended       { ... };
sub is_extended_right { ... }

sub maybe_anchor      {
  my $self = shift;
  return if $self->is_negative;
  return if $self->is_optional;
  return if $self->is_any;
  return 1;
};

# Check if the wrapped query may need to be sorted
# on focussing on a specific class.
# Normally spans are always sorted, but in case of
# a wrapped relation query, classed operands may
# be in arbitrary order. When focussing on these
# classes, the span has to me reordered.

sub maybe_unsorted { ... };

#############################
# Query Application methods #
#############################
sub index {
  my $self = shift;
  $self->{index} = shift;
};


sub filter_by {
  my $self = shift;
  $self->{filter} = shift;
};


# Deserialization of KoralQuery
sub from_koral {
  ...
};

# Serialization of KoralQuery
sub to_koral_query {
  my $self = shift;
  return {
    '@context' => CONTEXT,
    query => $self->to_koral_fragment
  };
};

# Overwritten
sub to_koral_fragment;

sub to_string;

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
