package Krawfish::Koral::Meta::Builder;
use Krawfish::Koral::Meta::Aggregate;

# TODO:
#   These should all be moved to ::Meta::Cluster::*
use Krawfish::Koral::Meta::Limit;
use Krawfish::Koral::Meta::Sort;
use Krawfish::Koral::Meta::Sort::Field;
use Krawfish::Koral::Meta::Aggregate::Frequencies;
use Krawfish::Koral::Meta::Aggregate::Fields;
use Krawfish::Koral::Meta::Aggregate::Length;
use Krawfish::Koral::Meta::Aggregate::Values;
use Krawfish::Koral::Meta::Group;
use Krawfish::Koral::Meta::Group::Fields;

# TODO:
#   Add an enrich-object to meta!

use Krawfish::Koral::Meta::Enrich;
use Krawfish::Koral::Meta::Enrich::Fields;
use Krawfish::Koral::Meta::Enrich::Snippet;

# TODO:
#   Add enrich for term_ids (necessary for sorting
#   by surface forms)

use Krawfish::Koral::Meta::Type::Key;
use Scalar::Util qw/blessed/;
use strict;
use warnings;

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


# Enrich with snippet
sub e_snippet {
  shift;
  return Krawfish::Koral::Meta::Enrich::Snippet->new(@_);
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


sub limit {
  shift;
  # start_index, items_per_page
  return Krawfish::Koral::Meta::Limit->new(@_);
};


1;

__END__
