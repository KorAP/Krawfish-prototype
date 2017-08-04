package Krawfish::Koral::Meta::Enrich::Snippet;
use Krawfish::Koral::Meta::Node::Enrich::Snippet;
use strict;
use warnings;

# Define the context and the annotations
# to retrieve for a match

sub new {
  my $class = shift;

  # Receive options
  my $self = shift // {};
  bless $self, $class;
};

sub type {
  'snippet'
};


sub normalize {
  $_[0];
};


sub identify {
  $_[0];
};

sub to_string {
  'snippet';
};


sub wrap {
  my ($self, $query) = @_;
    return Krawfish::Koral::Meta::Node::Enrich::Snippet->new(
    $query,
    { %$self }
  );
};

1;
