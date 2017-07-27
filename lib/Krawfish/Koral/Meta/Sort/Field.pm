package Krawfish::Koral::Meta::Sort::Field;
use Krawfish::Util::String qw/squote/;
use strict;
use warnings;

sub new {
  my $class = shift;
  bless {
    field => shift,
    desc => shift
  }, $class;
};

sub field {
  return $_[0]->{field};
};

sub to_string {
  my $str = 'field=' . squote($_[0]->{field});
  $str .= ($_[0]->{desc} ? '>' : '<');
  $str;
};

1;
