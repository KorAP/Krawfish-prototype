package Krawfish::Koral::Result::Enrich::Snippet::Highlight;
use strict;
use warnings;
use Role::Tiny::With;
use Krawfish::Log;

with 'Krawfish::Koral::Result::Enrich::Snippet::Markup';

use constant DEBUG => 0;


# Class number of highlight
sub number {
  my $self = shift;
  if (@_) {
    $self->{number} = shift;
    return $self;
  };
  return $self->{number};
};


sub clone {
  my $self = shift;
  return __PACKAGE__->new(
    start => $self->start,
    end => $self->end,
    start_char => $self->start_char,
    end_char => $self->end_char,
    opening => $self->is_opening,
    number => $self->number
  );
};


1;
