package Krawfish::Result::Segment::Enrich::Snippet::Element::Pagebreak;
use parent 'Krawfish::Result::Segment::Enrich::Snippet::Element';
use strict;
use warnings;

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
