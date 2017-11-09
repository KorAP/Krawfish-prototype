package Krawfish::Koral::Util::Row;
use Krawfish::Util::String;
use Mojo::ByteStream 'b';
use strict;
use warnings;


# Get group from columns
sub from_columns {
  my $class = shift;
  bless [@_], $class;
};


# Create group from signature
sub from_signature {
  my $class = shift;
  my $sig = shift;
  bless [map { unsquote($_) } split(/(?<=');(?=')/,b($sig)->b64_decode)], $class;
};


# Get colums
sub columns {
  $_[0]
};


# Get signature
sub signature {
  my $self = shift;
  return b(join(';', map { squote($_) } @$self))->b64_encode('');
};


1;
