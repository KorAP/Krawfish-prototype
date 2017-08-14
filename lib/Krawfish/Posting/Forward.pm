package Krawfish::Posting::Forward;
use strict;
use warnings;

# API:
#   ->preceding_data      # The whitespace data before the subtoken
#   ->subterm_id          # The current subterm identifier
#   ->annotations         # Get all annotations as terms
#   ->annotations(
#     foundry             # TODO: Think of more complex options!
#   )

sub new {
  my $class = shift;
  bless {@_}, $class;
};

sub doc_id {
  $_[0]->{doc_id};
};

sub term_id {
  $_[0]->{term_id};
};

sub preceding_data {
  $_[0]->{preceding_data} // '';
};

sub stream {
  $_[0]->{stream};
};


sub annotations {
  my $self = shift;

  my @anno = ();

  my $list = $self->stream;
  while ($list->[$self->{cur}] ne 'EOA') {
    $self->{cur} += 3; # skip foundry_id, layer_id, type
    my $anno_id = $list->[$self->{cur}++];
    my $data = $list->[$self->{cur}++];

    push @anno, [$anno_id, $data];
  };

  return @anno;
};

sub to_string {
  my $str = '[' . $_[0]->doc_id . ':#' . $_[0]->term_id;
  $str .= '$' . $_[0]->preceeding_data if $_[0]->preceeding_data;
  return $str .']';
};

1;
