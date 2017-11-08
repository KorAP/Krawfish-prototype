package Krawfish::Compile::Segment::Enrich::Snippet::Element::Pagebreak;
use strict;
use warnings;
use Role::Tiny;

with 'Krawfish::Compile::Segment::Enrich::Snippet::Element';

# TODO:
#   Probably remove this support and
#   add a more general "Inline" helper

sub new {
  my $self = shift;
  bless {
    start_char => shift,
    page_after => shift
  }, $class;
};

sub start_char {
  return $_[0]->{start_char};
};

sub end_char {
  return $_[0]->{end_char};
};

sub open_html {
  return '<span class="pagebreak" data-page-after="' . $self->{page_after} . '"></span>';
};

sub close_html {
  return '';
};

1;
