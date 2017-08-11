package Krawfish::Index::Forward::Annotation;
use Krawfish::Koral::Query::Term;
use Krawfish::Util::String qw/squote/;
use warnings;
use strict;


# Accepts a Krawfish::Koral::Query::Term object
sub new {
  my $class = shift;
  bless {
    term => shift,
    data => [@_]
  }, $class;
};


sub term {
  $_[0]->{term};
};


sub data {
  $_[0]->{data}
};


sub foundry_id {
  $_[0]->{foundry_id} // 0;
};


sub layer_id {
  $_[0]->{layer_id} // 0;
};


sub type {
  $_[0]->{term}->term_type;
};

sub term_id {
  $_[0]->{term_id};
};


sub identify {
  my ($self, $dict) = @_;

  my $term_id;
  my $term = $self->{term};
  my $term_str = $term->to_term;

  $term_id = $dict->term_id_by_term($term_str);

  # Term id is already known!
  if ($term_id) {
    $self->{term_id} = $term_id;
    $self->{foundry_id} = $dict->term_id_by_term('^' . $term->foundry) if $term->foundry;
    $self->{layer_id} = $dict->term_id_by_term('°' . $term->layer) if $term->layer;
    return $self;
  }

  # Term id is not yet given
  else {
    $self->{term_id} = $dict->add_term($term_str);
  };

  # Get term_id for foundry
  if ($term->foundry) {
    $term_id = $dict->term_id_by_term('^' . $term->foundry);
    $self->{foundry_id} = $term_id ? $term_id :
      $dict->add_term('^' . $term->foundry);
  };

  # Get term_id for layer
  if ($term->layer) {
    $term_id = $dict->term_id_by_term('°' . $term->layer);
    $self->{layer_id} = $term_id ? $term_id :
      $dict->add_term('°' . $term->layer);
  };

  return $self;
};


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

1;
