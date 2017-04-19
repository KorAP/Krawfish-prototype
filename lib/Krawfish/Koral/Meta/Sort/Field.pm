package Krawfish::Koral::Meta::Sort::Field;
use strict;
use warnings;

sub new {
  my $class = shift;
  bless {
    field => shift,
    desc => shift
  }, $class;
};

sub to_string {
  my $str = 'field=' . $_[0]->{field};
  $str .= ($_[0]->{desc} ? '>' : '<');
  $str;
};

1;
