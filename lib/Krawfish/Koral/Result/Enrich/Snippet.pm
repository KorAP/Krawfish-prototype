package Krawfish::Koral::Result::Enrich::Snippet;
use strict;
use warnings;
use Role::Tiny::With;

with 'Krawfish::Koral::Result::Inflatable';


# Constructor
sub new {
  my $class = shift;

  # match_ids
  bless {
    @_
  }, $class;
};


# Inflate term ids to terms
sub inflate {
  my ($self, $dict) = @_;
  my $hit = $self->{hit_ids};
  for (my $i = 0; $i < @$hit; $i++) {
    $hit->[$i] = $hit->[$i]->inflate($dict);
  };
  return $self;
};


# Stringification
sub to_string {
  my ($self, $id) = @_;
  return $self->key . ':' . join(',', map { $_->to_string($id) } @{$self->{hit_ids}});
};


# Key for KQ serialization
sub key {
  'snippet'
};


# Serialize KQ
sub to_koral_fragment {
  my $self = shift;
  return join('', map { $_->to_string } @{$self->{hit_ids}});
};


1;
