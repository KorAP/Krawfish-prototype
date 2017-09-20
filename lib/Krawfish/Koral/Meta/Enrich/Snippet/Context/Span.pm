package Krawfish::Koral::Meta::Enrich::Snippet::Context::Span;
use Krawfish::Koral::Query::Term;
use strict;
use warnings;

sub new {
  my ($class, $term_str, $count) = @_;

  # Parse term
  my $term = Krawfish::Koral::Query::Term->new($term_str);

  if ($term->term_type ne 'span') {
    warn qq!Term "$term_str" is no span, but a ! . $term->term_type . '!';
    return;
  };

  bless {
    count => $count,
    term => $term
  }, $class;
};

sub type {
  'context_span'
};

sub operations;

sub normalize {
  $_[0];
};


sub identify {
  my ($self, $dict) = @_;

  my $term = $self->{term};
  $self->{anno_id} = $dict->term_id_by_term($term->to_term);

  # Term not found
  return unless $self->{anno_id};

  # Translate all other elements
  $self->{layer_id} = $dict->term_id_by_term('&' . $term->layer);
  $self->{foundry_id}  = $dict->term_id_by_term('^' . $term->foundry);
  return $self;
};

sub term {
  $_[0]->{term};
};

sub count {
  $_[0]->{count};
};

sub to_string {
  my $self = shift;
  return 'span(' . $self->term->to_string . ',' . $self->count . ')';
};


1;
