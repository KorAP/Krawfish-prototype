package Krawfish::Result::Snippet::Spans;
use Krawfish::Log;
use strict;
use warnings;

use constant DEBUG => 1;

sub new {
  my $class = shift;
  bless {
    elements => [],
    text => ''
  }, $class;
};

sub add_element {
  my ($self, $element) = @_;
  push @{$self->{elements}}, $element;
};

sub add_text {
  my ($self, $text) = @_;
  $self->{text} .= $text;
  return $self;
};

sub to_html {
  my $self = shift;
  return $self->{text};
};

1;
