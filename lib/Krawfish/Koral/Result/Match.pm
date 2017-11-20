package Krawfish::Koral::Result::Match;
use Role::Tiny::With;
use Krawfish::Util::String qw/squote/;
use warnings;
use strict;

with 'Krawfish::Koral::Report';
with 'Krawfish::Posting::Span';
with 'Krawfish::Koral::Result::Inflatable';

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


  # In case a class != 0 is set - serialize
  if ($self->flags & 0b0111_1111_1111_1111) {
    $str .= '!' . join(',', $self->corpus_classes);
  };

  if ($self->payload->length) {
    $str .= '$' . $self->payload->to_string($id);
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
