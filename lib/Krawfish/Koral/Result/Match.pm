package Krawfish::Koral::Result::Match;
use parent 'Krawfish::Posting::Span';
use Krawfish::Util::String qw/squote/;
use warnings;
use strict;

# TODO:
#   Move Posting::Match, Posting::Aggregate, Posting::Group,
#   Posting etc. to Koral::Result

# TODO:
#   Rename Koral::Result::Match::* to Koral::Result::Enrich::*

# Matches are returned from searches and can be enriched
# with various information

# Enrichments can include
#   snippet
#   fields
#   sorting_criteria
#   segment_id
#   match_id
#   corpus flags

# Add an enrichment
sub add {
  my $self = shift;
  $self->{enrichments} //= [];
  push @{$self->{enrichments}}, @_;
};


# Inflate enrichments
sub inflate {
  my ($self, $dict) = @_;
  my $enrichments = $self->{enrichments} // [];
  for (my $i = 0; $i < @$enrichments; $i++) {
    $enrichments->[$i] = $enrichments->[$i]->inflate($dict);
  };
  return $self;
};


# Stringification
sub to_string {
  my ($self, $id) = @_;
  my $str = '[';

  # Identical to Posting
  $str .= $self->doc_id . ':' .
    $self->start . '-' .
    $self->end;

  if ($self->payload->length) {
    $str .= '$' . $self->payload->to_string;
  };

  foreach (@{$self->{enrichments}}) {
    $str .= '|' . $_->to_string($id);
  };

  return $str . ']';
};


# serialize to koralquery
sub to_koral_fragment {
  my $self = shift;
  my $match = {
    '@type' => 'koral:match'
  };

  # Add enrichments to match
  foreach (@{$self->{enrichments}}) {
    $match->{$_->key} = $_->to_koral_fragment
  };

  return $match;
};




1;
