package Krawfish::Collection;
use parent 'Krawfish::Query';
use strict;
use warnings;
use Krawfish::Posting::Match;

sub current_match {
  my $self = shift;
  return unless defined $self->{doc_id};
  return Krawfish::Posting::Match->new(
    doc_id => $self->{doc_id},
    start => $self->{start},
    end => $self->{end},
    payload => $self->{payload}
  );
};


1;
