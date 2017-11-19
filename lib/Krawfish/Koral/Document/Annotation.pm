package Krawfish::Koral::Document::Annotation;
use warnings;
use strict;
use Krawfish::Util::String qw/squote/;
use Krawfish::Util::Constants qw/:PREFIX/;
use Krawfish::Koral::Query::Term;
use Role::Tiny;

with 'Krawfish::Koral::Result::Inflatable';

# TODO:
#   Have common methods with
#   Krawfish::Koral::Result::Enrich::Snippet::Markup


# Accepts a Krawfish::Koral::Query::Term object
#
# TODO:
#   May as well only accept a term_id etc.
#   and needs to be inflated
sub new {
  my $class = shift;
  bless {
    term => shift,
    data => [@_]
  }, $class;
};


# Get term string
sub term {
  $_[0]->{term};
};


# Get data array
sub data {
  $_[0]->{data}
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
  my $term_str = $term->to_term;

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


# Stringify annotation
sub to_string {
  my $self = shift;
  my $str = '';

  if ($self->{term_id}) {
    $str .= $self->{term_id};
  }

  else {
    $str .= squote($self->{term}->to_term);
  };
  return $str . '$' . join(',',  @{$self->{data}});
};


# Turn the Annotation into a koral fragment
sub to_koral_fragment {
  return $_[0]->term->to_koral_fragment;
};

1;
