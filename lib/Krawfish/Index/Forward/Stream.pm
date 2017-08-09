package Krawfish::Index::Forward::Stream;
use Krawfish::Index::Forward::Subtoken;
use warnings;
use strict;

# This is one single stream of the forward index;
# TODO:
#   This should probably be part of Koral::Document::*

sub new {
  my $class = shift;
  bless [], $class;
};


# Get or set a subtoken
sub subtoken {
  my $self = shift;
  my $pos = shift;
  if (@_) {
    $self->[$pos] = Krawfish::Index::Forward::Subtoken->new(@_);
  };
  return $self->[$pos];
};


sub to_string {
  my $i = 0;
  return join '', map { '(' . ($i++) . ')' .  $_->to_string } @{$_[0]}
};

sub length {
  @{$_[0]};
};


sub identify {
  my ($self, $dict) = @_;

  foreach (@$self) {
    $_->identify($dict);
  };

  return $self;
};


1;
