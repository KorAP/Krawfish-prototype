package Krawfish::Query;
use strict;
use warnings;

# Current span object
sub current {
  my $self = shift;
  return unless defined $self->{doc_id};
  return Krawfish::Posting->new(
    doc_id  => $self->{doc_id},
    start   => $self->{start},
    end     => $self->{end},
    payload => $self->{payload}
  );
};

# Overwrite
sub next;

# Forward to next start position
sub next_pos;

sub skip_doc {
  my $self = shift;
  my $doc_id = shift;
  while ($self->{doc_id} && $self->{doc_id} < $doc_id) {
    $self->next;
  };
  return $self->{doc_id};
};

sub freq {
  -1;
};

# Overwrite
sub to_string {
  ...
};

1;
