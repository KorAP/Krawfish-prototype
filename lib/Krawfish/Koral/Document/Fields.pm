package Krawfish::Koral::Document::Fields;
use Krawfish::Koral::Document::FieldString;
use Krawfish::Koral::Document::FieldInt;
use Krawfish::Koral::Document::FieldStore;
use Krawfish::Koral::Document::FieldDate;
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
    Krawfish::Koral::Document::FieldString->new(
      key => $key,
      value => $value
    );
};


sub add_int {
  my $self = shift;
  my ($key, $value) = @_;

  # This may be an integer value
  push @{$self->operands},
    Krawfish::Koral::Document::FieldInt->new(
      key => $key,
      value => $value
    );
};


sub add_store {
  my $self = shift;
  my ($key, $value) = @_;

  # This may be an integer value
  push @{$self->operands},
    Krawfish::Koral::Document::FieldStore->new(
      key => $key,
      value => $value
    );
};


sub add_date {
  my $self = shift;
  my ($key, $value) = @_;

  # This may be an integer value
  push @{$self->operands},
    Krawfish::Koral::Document::FieldDate->new(
      key => $key,
      value => $value
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
