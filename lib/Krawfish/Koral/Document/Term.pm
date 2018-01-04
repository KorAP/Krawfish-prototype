package Krawfish::Koral::Document::Term;
use warnings;
use strict;
use Role::Tiny;
use Krawfish::Koral::Query::Term;
use Krawfish::Util::Constants qw/:PREFIX/;

# TODO:
#   Used by
#   Krawfish::Koral::Document::Annotation
#   Krawfish::Koral::Result::Enrich::Snippet::Markup


# Get term string
sub term {
  $_[0]->{term};
};


# Get foundry identifier
sub foundry_id {
  $_[0]->{foundry_id} // 0;
};


# Get layer identifier
sub layer_id {
  $_[0]->{layer_id} // 0;
};


# Get the term type
sub type {
  $_[0]->{term}->term_type;
};


# Get the term identifier
sub term_id {
  $_[0]->{term_id};
};


# Turn the term into ids
sub identify {
  my ($self, $dict) = @_;

  my $term_id;
  my $term = $self->{term};
  my $term_str = $term->to_neutral;

  $term_id = $dict->term_id_by_term($term_str);

  # Term id is already known!
  if ($term_id) {
    $self->{term_id} = $term_id;
    $self->{foundry_id} = $dict->term_id_by_term(FOUNDRY_PREF . $term->foundry) if $term->foundry;
    $self->{layer_id} = $dict->term_id_by_term(LAYER_PREF . $term->layer) if $term->layer;
    return $self;
  }

  # Term id is not yet given
  else {
    $self->{term_id} = $dict->add_term($term_str);
  };

  # Get term_id for foundry
  if ($term->foundry) {
    $term_id = $dict->term_id_by_term(FOUNDRY_PREF . $term->foundry);
    $self->{foundry_id} = $term_id ? $term_id :
      $dict->add_term(FOUNDRY_PREF . $term->foundry);
  };

  # Get term_id for layer
  if ($term->layer) {
    $term_id = $dict->term_id_by_term(LAYER_PREF . $term->layer);
    $self->{layer_id} = $term_id ? $term_id :
      $dict->add_term(LAYER_PREF . $term->layer);
  };

  return $self;
};


# Inflate
sub inflate {
  my ($self, $dict) = @_;

  return $self if $self->{term};

  # Term identifier is defined
  if ($self->{term_id}) {
    my $term_str = $dict->term_by_term_id($self->{term_id});
    $self->{term} = Krawfish::Koral::Query::Term->new($term_str);
    return $self;
  };

  return;
};



1;
