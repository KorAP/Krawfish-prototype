package Krawfish::Query;
use Krawfish::Log;
use strict;
use warnings;

use constant DEBUG => 0;

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

  # TODO: May have an offset value as well
};

# Overwrite
# TODO: Accepts a target doc
# TODO: Returns the doc_id of the current posting
sub next;

# Forward to next start position
sub next_greater_start;


sub skip_doc {
  my ($self, $doc_id) = @_;

  warn 'Skipping is not implemented yet';

  print_log('query', 'Skip to ' . $doc_id) if DEBUG;

  while (!$self->current || $self->current->doc_id < $doc_id) {
    $self->next or return;
  };

  return $self->current->doc_id;
};

# In Lucene it's exemplified:
# int advance(int target) {
#   int doc;
#   while ((doc = nextDoc()) < target) {
#   }
#   return doc;
# }

sub freq {
  -1;
};

# Overwrite
sub to_string {
  ...
};


# Override in Krawfish::Collection
sub current_match {
  return undef;
};

1;
