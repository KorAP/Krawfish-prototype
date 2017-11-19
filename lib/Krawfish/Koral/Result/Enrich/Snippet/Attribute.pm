package Krawfish::Koral::Result::Enrich::Snippet::Attribute;
use strict;
use warnings;
use Role::Tiny::With;

with 'Krawfish::Koral::Document::Annotation';
with 'Krawfish::Koral::Result::Enrich::Snippet::Markup';
with 'Krawfish::Koral::Result::Enrich::Snippet::Certainty';


# Start position of target
sub ref_tui {
  my $self = shift;
  if (@_) {
    $self->{target_start} = shift;
    return $self;
  };
  return $self->{target_start};
};


1;
