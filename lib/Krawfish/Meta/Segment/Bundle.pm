package Krawfish::Meta::Segment::Bundle;
use parent 'Krawfish::Meta';

sub current_bundle {
  $_[0]->{current_bundle};
};

sub current_match {
  $_[0]->{current_match};
};

sub current {
  return $_[0]->{query}->current;
};


sub next_bundle {
  ...
};


# These call methods in Posting::Bundle!
sub next {
  ...
};

sub max_freq {
  $_[0]->{query}->max_freq;
};


1;
