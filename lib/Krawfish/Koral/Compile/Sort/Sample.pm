package Krawfish::Koral::Compile::Sort::Sample;
use Krawfish::Koral::Compile::Node::Sort::Sample;
use Krawfish::Util::String qw/squote/;
use strict;
use warnings;

sub new {
  my $class = shift;
  bless {
    top_k => shift // 0
  }, $class;
};

# Set or get the top_k limitation!
sub top_k {
  my $self = shift;
  if (defined $_[0]) {
    $self->{top_k} = shift;
    return $self;
  };
  return $self->{top_k};
};


sub type {
  'sample';
};

sub to_string {
  return 'sample=' . $_[0]->{top_k};
};

sub normalize {
  $_[0];
};

sub identify {
  $_[0];
};

sub wrap {
  my ($self, $query) = @_;
  return Krawfish::Koral::Compile::Node::Sort::Sample->new(
    $query,
    $self->{top_k}
  );

};


1;
