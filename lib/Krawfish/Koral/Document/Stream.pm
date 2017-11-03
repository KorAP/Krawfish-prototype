package Krawfish::Koral::Document::Stream;
use Krawfish::Koral::Document::Subtoken;
use warnings;
use strict;

# This is one single stream of the forward index;

# It may also be used in Snippet creation, so it requires an inflate method as well!

sub new {
  my $class = shift;
  bless [], $class;
};


# Get or set a subtoken
sub subtoken {
  my $self = shift;
  my $pos = shift;
  if (@_) {
    my $subtoken = shift;

    unless ($subtoken->isa('Krawfish::Koral::Document::Subtoken')) {
      warn 'No subtoken from: ' . caller;
    };

    $self->[$pos] = $subtoken;
  };
  return $self->[$pos];
};


# Get the leangth of the stream
sub length {
  @{$_[0]};
};


# Identify
sub identify {
  my ($self, $dict) = @_;

  foreach (@$self) {
    $_->identify($dict);
  };

  return $self;
};


sub inflate {
  my ($self, $dict) = @_;

  foreach (@$self) {
    $_->inflate($dict);
  };

  return $self;
};


# Stringification
sub to_string {
  my ($self, $id) = @_;
  my $i = 0;
  return join '', map { '(' . ($i++) . ')' .  ($_->to_string($id) // '') } @$self
};


1;
