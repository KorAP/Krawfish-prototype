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


# Add an enrichment
sub add {
  my $self = shift;
  push @{$self->{enrichments}}, @_;
};


sub to_string2 {
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



# This is deprecated:

# Get or set field to match
sub fields {

  my $self = shift;
  my $data = shift;
  my $fields = ($self->{fields} //= {});

  if ($data) {
    while (my ($key,$value) = each %{$data}) {
      $fields->{$key} = $value;
    };
  };

  return $fields
};



# Get or set term ids to match
sub term_ids {
  my $self = shift;
  my ($class_nr, $data) = @_;
  my $term_ids = ($self->{term_ids} //= []);

  # No data to be set
  unless ($data) {
    return ($term_ids->[$class_nr] //= []);
  }
  else {
    return $term_ids->[$class_nr] = $data;
  };
};

sub sorting_criteria;

sub snippet;

sub segment_id;

sub match_id;


# serialize to koralquery
sub to_koral_query {
  ...
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

  #if ($self->{fields}) {
  #  $str .= '|';
  #  $str .= join ';', map {
  #    $_ . '=' . squote($self->{fields}->{$_})
  #  } sort keys %{$self->{fields}};
  #};

  if ($self->{field_ids}) {
    $str .= '|';
    $str .= join(',', @{$self->{field_ids}});
  };

  if ($self->{term_ids}) {
    $str .= '|term_ids=';
    foreach (my $i = 0; $i <= $#{$self->{term_ids}}; $i++) {
      my $list = $self->{term_ids} or next;
      $str .= (0 + $i) . ':' . join(',', @$list);
    };
  };

  return $str . ']';
};


1;
