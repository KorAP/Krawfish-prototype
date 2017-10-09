package Krawfish::Koral::Compile::Sort::No;
use Krawfish::Compile::Segment::Sort::No;
use Krawfish::Util::String qw/squote/;
use strict;
use warnings;

# This is a dummy sorter for non resolvable sortings

sub new {
  my $class = shift;
  bless {
    field => shift, # Is a Koral::Compile::Type
    desc => shift
  }, $class;
};

sub type {
  'no';
};

sub field {
  return $_[0]->{field};
};

sub desc {
  return $_[0]->{desc};
};

sub optimize {
  return Krawfish::Compile::Segment::Sort::No->new(
    $_[0]->{field}->term,
    $_[0]->{desc}
  );
};



sub identify {
  return $_[0];
};


sub to_string {
  my $str = 'no=' . $_[0]->{field}->to_string;
  $str .= ($_[0]->{desc} ? '>' : '<');
  $str;
};

1;
