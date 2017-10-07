package Krawfish::Meta::Segment::Bundle;
use parent 'Krawfish::Meta';
use Krawfish::Log;
use strict;
use warnings;

use constant DEBUG => 1;


# Get current bundle
sub current_bundle {
  $_[0]->{current_bundle};
};


# Get current match
sub current_match {
  $_[0]->{current_match};
};




# Get current posting
#sub current {
#  return $_[0]->{query}->current;
#};


# Get next bundle - this needs to be overwritten
sub next_bundle {
  ...
};


sub next {
  ...
};

sub current {
  $_[0]->{query}->current;
};



# Get frequency
sub max_freq {
  $_[0]->{query}->max_freq;
};


1;
