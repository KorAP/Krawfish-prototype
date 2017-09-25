package Krawfish::Koral::Result::Enrich::Snippet;
use strict;
use warnings;


# Constructor
sub new {
  my $class = shift;

  # match_ids
  bless { @_ }, $class;
};


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
  my $self = shift;
  return 'snippet:' . join(',', map { $_->to_string } @{$self->{hit_ids}});
};


# Stringification
sub to_term_string {
  my $self = shift;
  return 'snippet:' . join(',', map { $_->to_term_string } @{$self->{hit_ids}});
};


1;
