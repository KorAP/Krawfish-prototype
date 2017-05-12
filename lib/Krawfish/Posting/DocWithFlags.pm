package Krawfish::Posting::DocWithFlags;
use strict;
use warnings;
use Krawfish::Util::Bits 'bitstring';


sub new {
  my ($class, $id, $flags) = @_;
  bless [$id, $flags], $class;
};

# Current document
sub doc_id {
  return $_[0]->[0];
};

sub flags {
  return $_[0]->[1];
};

sub to_string {
  '[' . $_[0]->[0] .
    '$flags=' . bitstring($_[0]->[1]) . ']';
};

1;
