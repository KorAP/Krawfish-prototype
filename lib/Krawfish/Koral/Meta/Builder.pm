package Krawfish::Koral::Meta::Builder;
use strict;
use warnings;

use Krawfish::Koral::Meta::Aggregate;

# TODO:
#   These should all be moved to ::Meta::Cluster::*
use Krawfish::Koral::Meta::Limit;
use Krawfish::Koral::Meta::Sort;
use Krawfish::Koral::Meta::Sort::Field;
use Krawfish::Koral::Meta::Sort::Sample;
use Krawfish::Koral::Meta::Aggregate::Frequencies;
use Krawfish::Koral::Meta::Aggregate::Fields;
use Krawfish::Koral::Meta::Aggregate::Length;
use Krawfish::Koral::Meta::Aggregate::Values;
use Krawfish::Koral::Meta::Group;
use Krawfish::Koral::Meta::Group::Fields;
use Krawfish::Koral::Meta::Group::ClassFrequencies;

use Krawfish::Koral::Meta::Enrich;
use Krawfish::Koral::Meta::Enrich::Terms;
use Krawfish::Koral::Meta::Enrich::Fields;
use Krawfish::Koral::Meta::Enrich::Snippet;
use Krawfish::Koral::Meta::Enrich::Snippet::Context::Span;

use Krawfish::Koral::Meta::Type::Key;
use Scalar::Util qw/blessed/;

sub new {
  my $class = shift;
  bless [], $class;
};

#   $koral->meta(
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

sub aggregate {
  my $self = shift;
  return Krawfish::Koral::Meta::Aggregate->new(@_);
};

# Some aggregation types
# Aggregate frequencies
sub a_frequencies {
  return Krawfish::Koral::Meta::Aggregate::Frequencies->new;
};


# Aggregate fields
sub a_fields {
  shift;
  return Krawfish::Koral::Meta::Aggregate::Fields->new(
    map {
      blessed $_ ? $_ : Krawfish::Koral::Meta::Type::Key->new($_)
    } @_
  );
};


# Aggregate lengths of matches
sub a_length {
  return Krawfish::Koral::Meta::Aggregate::Length->new;
};


# Aggregate numerical values
sub a_values {
  shift;
  return Krawfish::Koral::Meta::Aggregate::Values->new(
    map {
      blessed $_ ? $_ : Krawfish::Koral::Meta::Type::Key->new($_)
    } @_
  );
};


# Enrich matched with additional information
sub enrich {
  shift;
  return Krawfish::Koral::Meta::Enrich->new(@_);
};


# Enrich with fields
sub e_fields {
  shift;
  return Krawfish::Koral::Meta::Enrich::Fields->new(
    map {
      blessed $_ ? $_ : Krawfish::Koral::Meta::Type::Key->new($_)
    } @_
  );
};


# Enrich with snippets
sub e_snippet {
  shift;
  # Accepts: left_context => $mb->e_char_context(5)
  return Krawfish::Koral::Meta::Enrich::Snippet->new(@_);
};


# Set char context
sub e_char_context {
  shift;
  my $count = shift;
  ...
  # return Krawfish::Koral::Meta::Enrich::Snippet::Context::Char->new($count);
};


# Set token context
sub e_token_context {
  shift;
  my ($count, $foundry) = @_;
  ...
  # return Krawfish::Koral::Meta::Enrich::Snippet::Context::Token->new($count, $foundry);
};


sub e_span_context {
  shift;
  my ($term, $count) = @_;
  return Krawfish::Koral::Meta::Enrich::Snippet::Context::Span->new($term, $count);
};

# Enrich with Term lists per class
sub e_terms {
  shift;
  return Krawfish::Koral::Meta::Enrich::Terms->new(@_);
};


# Grouping object
sub group_by {
  shift;
  return Krawfish::Koral::Meta::Group->new(@_);
};


# Group by fields
sub g_fields {
  shift;
  return Krawfish::Koral::Meta::Group::Fields->new(
    map {
      blessed $_ ? $_ : Krawfish::Koral::Meta::Type::Key->new($_)
    } @_
  );
};


# Group by class frequencies
sub g_class_freq {
  shift;
  return Krawfish::Koral::Meta::Group::ClassFrequencies->new(@_);
};


# Sort results by different criteria
sub sort_by {
  shift;
  return Krawfish::Koral::Meta::Sort->new(@_);
};


# Some sorting criteria
sub s_field {
  shift;
  return Krawfish::Koral::Meta::Sort::Field->new(
    blessed $_[0] ? $_[0] : Krawfish::Koral::Meta::Type::Key->new($_[0]),
    $_[1]
  );
};


# Get a sample of size X
sub s_sample {
  shift;
  return Krawfish::Koral::Meta::Sort::Sample->new(shift);
};

# TODO:
#   s_class (sort by the surface form of a class, necessary for concordances)


sub limit {
  shift;
  # start_index, items_per_page
  return Krawfish::Koral::Meta::Limit->new(@_);
};


1;

__END__
