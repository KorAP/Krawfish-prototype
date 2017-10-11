package Krawfish::Koral::Document::Stream;
use Krawfish::Koral::Document::Subtoken;
use warnings;
use strict;

# This is one single stream of the forward index;

sub new {
  my $class = shift;
  bless [], $class;
};


# Get or set a subtoken
sub subtoken {
  my $self = shift;
  my $pos = shift;
  if (@_) {
    $self->[$pos] = Krawfish::Koral::Document::Subtoken->new(@_);
  };
  return $self->[$pos];
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


sub to_string {
  my ($self, $id) = @_;
  my $i = 0;
  return join '', map { '(' . ($i++) . ')' .  ($_->to_string($id) // '') } @$self
};

sub to_id_string {
  my $i = 0;
  return join '', map { '(' . ($i++) . ')' .  ($_->to_id_string // '') } @{$_[0]}
};

1;
