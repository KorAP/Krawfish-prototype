package Krawfish::Query::Constraint::Depth;
use parent 'Krawfish::Query::Base::Dual';
use Krawfish::Query::Base::Dual;
use strict;
use warnings;

# TODO: THIS IS CURRENTLY JUST A MOCKUP

# Check the nodes for depth
# The relevant information is in the last added
# node payload of the same foundry/layer
#
# direct child: min==max=1
# direct parent: min==max=-1
# ancestor: min=0, max=256

sub new {
  my $class = shift;
  bless {
    min => shift,
    max => shift
  }, $class;
};


# Overwrite
sub check {
  my $self = shift;
  my ($first, $second) = @_;
  if (
    (($first->{depth} + $self->{min}) <= $second->{depth}) &&
      (($first->{depth} + $self->{max}) >= $second->{depth})
    ) {
    return NEXTA | NEXTB | MATCH;
  };
  return NEXTA | NEXTB;
};

1;
