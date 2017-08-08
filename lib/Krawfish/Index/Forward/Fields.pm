package Krawfish::Index::Forward::Fields;
use Krawfish::Index::Forward::FieldString;
use Krawfish::Index::Forward::FieldInt;
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
  push @$self, Krawfish::Index::Forward::FieldString->new($key, $value);
};


sub add_int {
  my $self = shift;
  my ($key, $value) = @_;

  # This may be an integer value
  push @$self, Krawfish::Index::Forward::FieldInt->new($key, $value);
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
