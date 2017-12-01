package Krawfish::Koral::Result::Match;
use Krawfish::Koral::Result::Enrich::Criteria;
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


# Return sort criteria object
sub sorted_by {
  my $self = shift;
  $self->{sorted_by} //= Krawfish::Koral::Result::Enrich::Criteria->new;
  return $self->{sorted_by};
};


# Get the uuid if defined
sub uuid {
  if ($_[0]->{sorted_by}) {
    return $_[0]->{sorted_by}->uuid;
  };
  return;
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

  if (defined $self->{sorted_by}) {
    $str .= '::' . $self->{sorted_by}->to_string($id);
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
