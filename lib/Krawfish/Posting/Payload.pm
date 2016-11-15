package Krawfish::Posting::Payload;
use parent 'Exporter';
use strict;
use warnings;
use Scalar::Util qw/blessed/;

use constant {
  PTI_CLASS => 0
};

our (@EXPORT);

@EXPORT = qw/PTI_CLASS/;

sub new {
  my $class = shift;
  bless [], $class;
};

sub length {
  scalar @{$_[0]};
};

sub copy_from {
  my $self = shift;
  my $payload = shift;
  foreach (@$payload) {
    $self->add(@$_);
  };
  return $self;
};

sub add {
  my $self = shift;
  push @{$self}, [@_];
  return $self;
};

sub clone {
  my $self = shift;
  my $new = __PACKAGE__->new;
  foreach (@$self) {
    $new->add(@$_);
  };
  return $new;
};

sub to_string {
  my $self = shift;
  return join ('|', map { join(',', @{$_}) } @$self );
};

1;
