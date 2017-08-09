package Krawfish::Index::FieldValue;
use parent 'Krawfish::Index::PostingPointer';
use Krawfish::Log;
use strict;
use warnings;

# TODO:
#   This is deprecated in favor of Forward::*

# All values are stored as varints in a skiplist
# augmented postingslist

use constant DEBUG => 0;

# Override slow method for frequency counting
sub freq_in_doc {
  1;
};

# Directly return current value
sub value {
  my $self = shift;
  $self->{list}->at($self->pos)->[1] or return;
};

1;
