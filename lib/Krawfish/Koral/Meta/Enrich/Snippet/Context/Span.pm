package Krawfish::Koral::Meta::Enrich::Snippet::Context::Span;
use Krawfish::Koral::Query::Term;
use Krawfish::Log;
use strict;
use warnings;

use constant DEBUG => 1;

sub new {
  my ($class, $term_str, $count) = @_;

  # Parse term
  my $term = Krawfish::Koral::Query::Term->new($term_str);

  if ($term->term_type ne 'span') {
    if (DEBUG) {
      print_log(
        'k_context_span',
        qq!Term "$term_str" is no span, but a ! . $term->term_type . '!'
      );
    };
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

sub operations {

};

sub normalize {
  $_[0];
};


sub identify {
  my ($self, $dict) = @_;

  my $term = $self->{term};

  $self->{anno_id} = $dict->term_id_by_term($term->to_term);

  if (DEBUG) {
    print_log('k_context_span', 'Identify annotation for ' . $term->to_term);
  };

  # Term not found
  return unless $self->{anno_id};

  # Translate all other elements
  $self->{foundry_id}  = $dict->term_id_by_term('^' . $term->foundry);

  if (DEBUG) {
    print_log('k_context_span', 'Identify layer for ^' . $term->foundry);
  };

  $self->{layer_id} = $dict->term_id_by_term('&' . $term->layer);

  if (DEBUG) {
    print_log('k_context_span', 'Identify layer for &' . $term->layer);
  };

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
  my $str = 'span(';
  if ($self->{anno_id}) {
    $str .= '#' . $self->{foundry_id} . '/#' . $self->{layer_id} . '=#' . $self->{anno_id}
  }
  else {
    $str .= $self->term->to_string
  };
  return $str . ',' . $self->count . ')';
};


1;
