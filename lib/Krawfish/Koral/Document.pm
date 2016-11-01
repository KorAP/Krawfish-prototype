package Krawfish::Koral::Document;
use Krawfish::Koral::Query::Token;
use strict;
use warnings;

# Representation of a document
sub new {
  my $class = shift;
  my $self = bless {}, $class;

  return $self unless @_;

  my $koral = shift;
  if ($koral->{content}) {
    $self->content($koral->{content});
  };

  # Parse segments
  if ($koral->{segments}) {

    # Todo: Parse and sort
    $self->{segments} = $koral->{segments};
  };

  # Parse annotations
  if ($koral->{annotation}) {

    # TODO: All annotations need to be wrapped
    my @annotations = ();
    foreach my $item (@{$koral->{annotation}}) {
      if ($item->{'@type'} eq 'koral:token') {
        my $token = Krawfish::Koral::Query::Token->new($item);

        unless (scalar $item->{segments}) {
        }
      };
    };
  };

  return $self;
};


# Primary data
sub content {
  my $self = shift;
  if (@_) {
    $self->{content} = shift;
  };
  return $self->{content};
};


# Segments
sub segments {
  my $self = shift;
  if (@_) {
    $self->{segments} = shift;
  };
  return $self->{segments};
};

sub annotations {
};

# Return segment list or nothing
sub _segment_list {
  my $item = shift;
  my @posting;

  if ($item->{segments}) {

    @posting = ($item->{segments}->[0]);

   if ($item->{segments}->[1]) {

     # The end is AFTER the second segment
      push @posting, $item->{segments}->[1];
    };

    return @posting;
  };

  return;
};


1;
