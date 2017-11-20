package Krawfish::Query::Constraint::Depth;
use Role::Tiny::With;
use Krawfish::Query::Base::Dual;
use strict;
use warnings;

with 'Krawfish::Query::Constraint::Base';


# THIS IS CURRENTLY JUST A MOCKUP

# Check the nodes for depth
# The relevant information is in the last added
# node payload of the same foundry/layer
#
# direct child: min==max=1
# direct parent: min==max=-1
# ancestor: min=0, max=256


# Constructor
sub new {
  my $class = shift;
  bless {
    min => shift,
    max => shift
  }, $class;
};


# Clone query
sub clone {
  __PACKAGE__->new(
    $_[0]->{min},
    $_[0]->{max}
  );
};


# Check configuration
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
