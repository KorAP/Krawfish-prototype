package Krawfish::Posting;
use overload '""' => sub { $_[0]->to_string }, fallback => 1;
use strict;
use warnings;

sub new {
  my $class = shift;
  bless { @_ }, $class;
};

# Current document
sub doc_id {
  return $_[0]->{doc_id};
};


# Start of span
sub start {
  return $_[0]->{start};
};


# End of span
sub end {
  return $_[0]->{end};
};


sub to_string {
  my $self = shift;
  return '[' .
    $self->doc_id . ':' .
    $self->start . '-' .
    $self->end . ']';
};

1;
