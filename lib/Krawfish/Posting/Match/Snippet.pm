package Krawfish::Posting::Match::Snippet;
use strict;
use warnings;

sub new {
  my $class = shift;

  # match_ids
  bless { @_ }, $class;
};

sub to_string {
  my $self = shift;

  if ($self->{match}) {
    return 'snippet:' . $self->{match};
  }
  else {
    return 'snippet:' . join(',', map { ref $_ ? ${$_} : '#' . $_ } @{$self->{match_ids}});
  }
};

1;
