package Krawfish::Koral::Document::Fields;
use Krawfish::Koral::Document::FieldString;
use Krawfish::Koral::Document::FieldInt;
use Krawfish::Koral::Document::FieldStore;
use warnings;
use strict;

sub new {
  my $class = shift;
  bless [], $class;
};

sub add_string {
  my $self = shift;
  my ($key, $value) = @_;

  # This may be an integer value
  push @$self, Krawfish::Koral::Document::FieldString->new(
    key => $key,
    value => $value
  );
};


sub add_int {
  my $self = shift;
  my ($key, $value) = @_;

  # This may be an integer value
  push @$self, Krawfish::Koral::Document::FieldInt->new(
    key => $key,
    value => $value
  );
};


sub add_store {
  my $self = shift;
  my ($key, $value) = @_;

  # This may be an integer value
  push @$self, Krawfish::Koral::Document::FieldStore->new(
    key => $key,
    value => $value
  );
};


sub to_string {
  return join(';', map { $_->to_string } @{$_[0]});
};


sub identify {
  my ($self, $dict) = @_;
  foreach (@$self) {
    $_->identify($dict);
  };
  return $self;
};


1;
