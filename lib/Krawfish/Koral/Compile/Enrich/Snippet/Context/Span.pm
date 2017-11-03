package Krawfish::Koral::Compile::Enrich::Snippet::Context::Span;
use Krawfish::Compile::Segment::Enrich::Snippet::Context::Span;
use Krawfish::Util::Constants qw/:PREFIX/;
use Krawfish::Koral::Query::Term;
use Krawfish::Log;
use strict;
use warnings;

# This is an inflatable!

use constant {
  DEBUG => 0,
  MAX_TOKENS => 4096
};


# Constructor
sub new {
  my ($class, $term_str, $count, $max) = @_;

  # Parse term
  my $term = Krawfish::Koral::Query::Term->new($term_str);

  if ($term->term_type ne 'span') {
    if (DEBUG) {
      print_log(
        'k_ctx_span',
        qq!Term "$term_str" is no span, but a ! . $term->term_type . '!'
      );
    };
    return;
  };

  bless {
    count => $count,
    term  => $term,
    max   => $max // MAX_TOKENS
  }, $class;
};

sub type {
  'context_span'
};


# Normalize span
sub normalize {
  $_[0];
};


# Identify context
sub identify {
  my ($self, $dict) = @_;

  my $term = $self->{term};

  $self->{anno_id} = $dict->term_id_by_term($term->to_term);

  if (DEBUG) {
    print_log('k_ctx_span', 'Identify annotation for ' . $term->to_term);
  };

  # Term not found
  return unless $self->{anno_id};

  # Translate all other elements
  $self->{foundry_id}  = $dict->term_id_by_term(FOUNDRY_PREF . $term->foundry);

  if (DEBUG) {
    print_log('k_ctx_span', 'Identify layer for ' . $term->foundry);
  };

  $self->{layer_id} = $dict->term_id_by_term(LAYER_PREF . $term->layer);

  if (DEBUG) {
    print_log('k_ctx_span', 'Identify layer for ' . $term->layer);
  };

  return $self;
};


# Get the term value
sub term {
  $_[0]->{term};
};


# Get the count
sub count {
  $_[0]->{count} // 0;
};


# Get the maximum value
sub max {
  $_[0]->{max};
};


sub anno_id {
  $_[0]->{anno_id};
};


sub layer_id {
  $_[0]->{layer_id};
};


sub foundry_id {
  $_[0]->{foundry_id};
};


# Adapt element to segment
sub optimize {
  my ($self, $segment) = @_;
  return Krawfish::Compile::Segment::Enrich::Snippet::Context::Span->new(
    foundry_id => $self->foundry_id,
    layer_id   => $self->layer_id,
    anno_id    => $self->anno_id,
    count      => $self->count,
    max        => $self->max
  );
};


# Stringify
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
