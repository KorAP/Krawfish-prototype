package Krawfish::Posting::Payload;
use parent 'Exporter';
use strict;
use warnings;
use Scalar::Util qw/blessed/;


# Class representing payload data


use constant {
  PTI_CLASS => 0
};

our (@EXPORT);

@EXPORT = qw/PTI_CLASS/;


# Constructor
sub new {
  my $class = shift;
  bless [], $class;
};


# Get length of payload
sub length {
  scalar @{$_[0]};
};


# Copy data from other payload
sub copy_from {
  my ($self, $payload) = @_;
  foreach (@$payload) {
    $self->add(@$_);
  };
  return $self;
};


# Add data to payload
sub add {
  my $self = shift;
  push @{$self}, [@_];
  return $self;
};


# Clone payload
sub clone {
  my $self = shift;
  my $new = __PACKAGE__->new;
  foreach (@$self) {
    $new->add(@$_);
  };
  return $new;
};


# Stringification
sub to_string {
  my $self = shift;
  return join ('|', map { join(',', @{$_}) } @$self );
};


# Get as array
sub to_array {
  @{$_[0]};
};


# Signature of the payload
sub to_sorted_string {
  my $self = shift;
  return join('|', sort _payload_sort $self->to_array);
};


# Sort payload entries for signature
sub _payload_sort {
  my $i = 0;

  # Iterate over all positions in payload
  while (1) {

    # At least one entry does not exist anymore
    if (!$a->[$i] || !$b->[$i]) {

      # No more entries in payload
      if (!$a->[$i] && !$b->[$i]) {
        return 0;
      }

      # List are uneven
      elsif (!$a->[$i]) {
        return -1;
      };
      return 0;
    }

    # Entries differ
    elsif ($a->[$i] < $b->[$i]) {
      return -1;
    }
    elsif ($a->[$i] > $b->[$i]) {
      return 1;
    };
    $i++;
  };
};


# Compare payloads
sub same_as {
  my ($self, $comp) = @_;
  return if $self->to_sorted_string ne $comp->to_sorted_string;
  return 1;
};

1;
