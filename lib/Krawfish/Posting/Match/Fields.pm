package Krawfish::Posting::Match::Fields;
use strict;
use warnings;

sub new {
  my $class = shift;
  bless {
    field_ids => [@_],
    fields => undef,
  }, $class;
};

sub to_string {
  my $self = shift;

  if ($self->{fields}) {
    return 'fields:' . join(',', @{$self->{fields}});
  }
  else {
    return 'fields:' . join(',', map { '#' . $_ } @{$self->{field_ids}});
  }
};

1;
