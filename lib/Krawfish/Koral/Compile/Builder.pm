package Krawfish::Koral::Compile::Builder;
use strict;
use warnings;

use Krawfish::Koral::Compile::Aggregate;

# TODO:
#   These should all be moved to ::Compile::Cluster::*
use Krawfish::Koral::Compile::Limit;
use Krawfish::Koral::Compile::Sort;
use Krawfish::Koral::Compile::Sort::Field;
use Krawfish::Koral::Compile::Sort::Sample;
use Krawfish::Koral::Compile::Aggregate::Frequencies;
use Krawfish::Koral::Compile::Aggregate::Fields;
use Krawfish::Koral::Compile::Aggregate::Length;
use Krawfish::Koral::Compile::Aggregate::Values;
use Krawfish::Koral::Compile::Group;
use Krawfish::Koral::Compile::Group::Aggregate;
use Krawfish::Koral::Compile::Group::Fields;
use Krawfish::Koral::Compile::Group::ClassFrequencies;

use Krawfish::Koral::Compile::Enrich;
use Krawfish::Koral::Compile::Enrich::Terms;
use Krawfish::Koral::Compile::Enrich::Fields;
use Krawfish::Koral::Compile::Enrich::Snippet;
use Krawfish::Koral::Compile::Enrich::Snippet::Context::Span;
use Krawfish::Koral::Compile::Enrich::CorpusClasses;

use Krawfish::Koral::Compile::Type::Key;
use Scalar::Util qw/blessed/;

# Build compile query
#
#   $koral->compile(
#     $mb->aggregate(
#       $mb->a_frequencies,
#       $mb->a_fields('license'),
#       $mb->a_fields('corpus'),
#       $mb->a_length
#     ),
#     $mb->start_index(0),
#     $mn->items_per_page(20)
#     $mb->sort_by(
#       $mb->sort_field('author', 1)
#     ),
#     $mb->fields('author')
#     $mb->snippet('')

# Constructor
sub new {
  my $class = shift;
  bless [], $class;
};


# Aggregate
sub aggregate {
  my $self = shift;
  return Krawfish::Koral::Compile::Aggregate->new(@_);
};


# Aggregate on groups
sub group_aggregate {
  my $self = shift;
  return Krawfish::Koral::Compile::Group::Aggregate->new(@_);
};


# Some aggregation types
# Aggregate frequencies
sub a_frequencies {
  return Krawfish::Koral::Compile::Aggregate::Frequencies->new;
};


# Aggregate fields
sub a_fields {
  shift;
  return Krawfish::Koral::Compile::Aggregate::Fields->new(
    map {
      blessed $_ ? $_ : Krawfish::Koral::Compile::Type::Key->new($_)
    } @_
  );
};


# Aggregate lengths of matches
sub a_length {
  return Krawfish::Koral::Compile::Aggregate::Length->new;
};


# Aggregate numerical values
sub a_values {
  shift;
  return Krawfish::Koral::Compile::Aggregate::Values->new(
    map {
      blessed $_ ? $_ : Krawfish::Koral::Compile::Type::Key->new($_)
    } @_
  );
};


# Enrich matched with additional information
sub enrich {
  shift;
  return Krawfish::Koral::Compile::Enrich->new(@_);
};


# Enrich with fields
sub e_fields {
  shift;
  return Krawfish::Koral::Compile::Enrich::Fields->new(
    map {
      blessed $_ ? $_ : Krawfish::Koral::Compile::Type::Key->new($_)
    } @_
  );
};


# Enrich with snippets
sub e_snippet {
  shift;
  # Accepts:
  #   left_context => $mb->e_char_context(5)
  #   format => 'html' || 'koralquery'
  return Krawfish::Koral::Compile::Enrich::Snippet->new(@_);
};


# Enrich with corpus classes
sub e_corpus_classes {
  shift;
  return Krawfish::Koral::Compile::Enrich::CorpusClasses->new(@_);
};


# Set char context
sub e_char_context {
  shift;
  my $count = shift;
  ...
  # return Krawfish::Koral::Compile::Enrich::Snippet::Context::Char->new($count);
};


# Set token context
sub e_token_context {
  shift;
  my ($count, $foundry) = @_;
  ...
  # return Krawfish::Koral::Compile::Enrich::Snippet::Context::Token->new($count, $foundry);
};


# Enrich with span context
sub e_span_context {
  shift;
  my ($term, $count) = @_;
  return Krawfish::Koral::Compile::Enrich::Snippet::Context::Span->new(
    $term,
    $count
  );
};


sub e_inline {
  # TODO:
  #   Add inline annotation information, like
  #   e_inline(
  #     span => 'dereko/s=pb',
  #     start => '<span class="pb">',
  #     content => '@page-after'
  #     end => '</span>
  # )
  ...
};


# Enrich with Term lists per class
sub e_terms {
  shift;
  return Krawfish::Koral::Compile::Enrich::Terms->new(@_);
};


# Grouping object
sub group_by {
  shift;
  return Krawfish::Koral::Compile::Group->new(@_);
};


# Group by fields
sub g_fields {
  shift;
  return Krawfish::Koral::Compile::Group::Fields->new(
    map {
      blessed $_ ? $_ : Krawfish::Koral::Compile::Type::Key->new($_)
    } @_
  );
};


# Group by class frequencies
sub g_class_freq {
  shift;
  return Krawfish::Koral::Compile::Group::ClassFrequencies->new(@_);
};


# Sort results by different criteria
sub sort_by {
  shift;
  return Krawfish::Koral::Compile::Sort->new(@_);
};


# Some sorting criteria
sub s_field {
  shift;
  return Krawfish::Koral::Compile::Sort::Field->new(
    blessed $_[0] ? $_[0] : Krawfish::Koral::Compile::Type::Key->new($_[0]),
    $_[1]
  );
};


# Get a sample of size X
sub s_sample {
  shift;
  return Krawfish::Koral::Compile::Sort::Sample->new(shift);
};

# TODO:
#   s_class
#   (sort by the surface form of a class, necessary for concordances)


sub limit {
  shift;
  # start_index, items_per_page
  return Krawfish::Koral::Compile::Limit->new(@_);
};


1;

__END__
