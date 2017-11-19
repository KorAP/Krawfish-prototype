package Krawfish::Koral::Result::Enrich::Snippet::Relation;
use strict;
use warnings;
use Role::Tiny::With;
use Krawfish::Log;

with 'Krawfish::Koral::Document::Annotation';
with 'Krawfish::Koral::Result::Enrich::Snippet::Markup';
with 'Krawfish::Koral::Result::Enrich::Snippet::TUI';
with 'Krawfish::Koral::Result::Enrich::Snippet::Certainty';

use constant DEBUG => 0;

sub left_to_right {
  return $self->{left_to_right};
};

# Start position of right part
sub right_start {
  my $self = shift;
  if (@_) {
    $self->{target_start} = shift;
    return $self;
  };
  return $self->{target_start};
};


# End position of the right part
sub right_end {
  my $self = shift;
  if (@_) {
    $self->{target_end} = shift;
    return $self;
  };
  return $self->{target_end};
};


# TUI of source
sub source_tui {
  my $self = shift;
  if (@_) {
    $self->{source_tui} = shift;
    return $self;
  };
  return $self->{source_tui};
};


# TUI of target
sub target_tui {
  my $self = shift;
  if (@_) {
    $self->{target_tui} = shift;
    return $self;
  };
  return $self->{target_tui};
};


1;
