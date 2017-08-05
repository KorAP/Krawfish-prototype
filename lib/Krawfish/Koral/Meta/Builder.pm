package Krawfish::Koral::Meta::Builder;
use Krawfish::Koral::Meta::Aggregate;

# TODO:
#   These should all be moved to ::Meta::Cluster::*
use Krawfish::Koral::Meta::Limit;
use Krawfish::Koral::Meta::Sort;
use Krawfish::Koral::Meta::Sort::Field;
use Krawfish::Koral::Meta::Aggregate::Frequencies;
use Krawfish::Koral::Meta::Aggregate::Facets;
use Krawfish::Koral::Meta::Aggregate::Length;
use Krawfish::Koral::Meta::Aggregate::Values;
use Krawfish::Koral::Meta::Group;
use Krawfish::Koral::Meta::Group::Fields;

# TODO:
#   Add an enrich-object to meta!

use Krawfish::Koral::Meta::Enrich::Fields;
use Krawfish::Koral::Meta::Enrich::Snippet;

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
#       $mb->aggr_frequencies,
#       $mb->aggr_facets('license'),
#       $mb->aggr_facets('corpus'),
#       $mb->aggr_length
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


# Aggregate facets
# TODO:
#   Rename to fields, as this is similar to
#   'group by fields' and 'enrich with fields'
sub a_facets {
  shift;
  return Krawfish::Koral::Meta::Aggregate::Facets->new(
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


# Enrich with fields
# TODO:
#   There may be an enrich type with fields and snippets instead
sub fields {
  shift;
  return Krawfish::Koral::Meta::Enrich::Fields->new(
    map {
      blessed $_ ? $_ : Krawfish::Koral::Meta::Type::Key->new($_)
    } @_
  );
};

# TODO:
#   Create enrich group, so this can be stripped from
#   segment queries
sub snippet {
  shift;
  return Krawfish::Koral::Meta::Enrich::Snippet->new(@_);
};


# Sort results by different criteria
sub sort_by {
  shift;
  return Krawfish::Koral::Meta::Sort->new(@_);
};


sub group_by {
  shift;
  return Krawfish::Koral::Meta::Group->new(@_);
};

sub g_fields {
  shift;
  return Krawfish::Koral::Meta::Group::Fields->new(
    map {
      blessed $_ ? $_ : Krawfish::Koral::Meta::Type::Key->new($_)
    } @_
  );
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


# Sort methods:
sub field_sort_by {
  my $self = shift;
  my ($field, $desc) = @_;
  push @{$self->{field_sort}},
    [$field, $desc // 0];
  return @_;
};

sub field_sort_asc_by {
  my $self = shift;
  $self->field_sort_by(shift);
  $self;
};

sub field_sort_desc_by {
  my $self = shift;
  $self->field_sort_by(shift, 1);
  $self;
};


sub field_count {
  my $self = shift;
  $self->{field_count} //= [];
  push @{$self->{field_count}}, shift;
  $self;
};


sub limit {
  my $self = shift;
  if (@_ == 2) {
    $self->start_index(shift());
    $self->items_per_page(shift());
  }
  else {
    $self->start_index(0);
    $self->items_per_page(shift());
  };
  $self;
};

