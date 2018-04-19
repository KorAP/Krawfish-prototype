package Krawfish::Koral::Document::Fields;
use Krawfish::Koral::Document::Field::String;
use Krawfish::Koral::Document::Field::Integer;
use Krawfish::Koral::Document::Field::Store;
use Krawfish::Koral::Document::Field::DateRange;
use warnings;
use strict;

# TODO:
#   Introduce operands

sub new {
  my $class = shift;
  bless {
    operands => [@_]
  }, $class;
};


sub add_string {
  my $self = shift;
  my ($key, $value) = @_;

  # This may be an integer value
  push @{$self->operands},
    Krawfish::Koral::Document::Field::String->new(
      key => $key,
      value => $value
    );
};


sub add_int {
  my $self = shift;
  my ($key, $value) = @_;

  # This may be an integer value
  push @{$self->operands},
    Krawfish::Koral::Document::Field::Integer->new(
      key => $key,
      value => $value
    );
};


sub add_store {
  my $self = shift;
  my ($key, $value) = @_;

  # This may be an integer value
  push @{$self->operands},
    Krawfish::Koral::Document::Field::Store->new(
      key => $key,
      value => $value
    );
};


sub add_date {
  my $self = shift;
  my ($key, $from, $to) = @_;

  # This may be an integer value
  push @{$self->operands},
    Krawfish::Koral::Document::Field::DateRange->new(
      key => $key,
      value => $from
    );
};


sub to_string {
  my ($self, $id) = @_;
  return join(';', map { $_->to_string($id) } @{$self->operands});
};


# Translate to term identities
sub identify {
  my ($self, $dict) = @_;
  foreach (@{$self->operands}) {
    $_->identify($dict);
  };
  return $self;
};


# Get operands
# TODO: Duplicate to Corpus
sub operands {
  my $self = shift;
  if (@_) {
    $self->{operands} = shift;
  };
  $self->{operands};
};


1;
