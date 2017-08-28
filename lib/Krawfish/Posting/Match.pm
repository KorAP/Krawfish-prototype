package Krawfish::Posting::Match;
use parent 'Krawfish::Posting';
use Krawfish::Util::String qw/squote/;
use warnings;
use strict;


# Matches are returned from searches and can be enriched
# with various information

# TODO:
#   there should only be one additional parameter called "enrichments"
#   that would contain an array of enrichments, that can be "to_koral_query"ied,
#   stringified, inflated etc.

# Enrichments can include
#   snippet
#   fields
#   sorting_criteria
#   segment_id
#   match_id


# Add an enrichment
sub add {
  my $self = shift;
  $self->{enrichments} //= [];
  push @{$self->{enrichments}}, @_;
};


sub inflate {
  my ($self, $dict) = @_;
  my $enrichments = $self->{enrichments};
  for (my $i = 0; $i < @$enrichments; $i++) {
    $enrichments->[$i] = $enrichments->[$i]->inflate($dict);
  };
  return $self;
};

# Stringification
sub to_string {
  my $self = shift;
  my $str = '[';

  # Identical to Posting
  $str .= $self->doc_id . ':' .
    $self->start . '-' .
    $self->end;

  if ($self->payload->length) {
    $str .= '$' . $self->payload->to_string;
  };

  foreach (@{$self->{enrichments}}) {
    $str .= '|' . $_->to_string;
  };

  return $str . ']';
};


# serialize to koralquery
sub to_koral_query {
  ...
};




1;