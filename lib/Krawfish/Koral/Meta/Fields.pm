package Krawfish::Koral::Meta::Fields;
use Krawfish::Result::Node::Fields;
use Krawfish::Util::String qw/squote/;
use List::MoreUtils qw/uniq/;
use strict;
use warnings;

sub new {
  my $class = shift;
  bless [@_], $class;
};

sub type {
  'fields';
};

# Get or set operations
sub operations {
  my $self = shift;
  if (@_) {
    @$self = @_;
    return $self;
  };
  return @$self;
};


sub to_string {
  my $self = shift;
  return 'fields=[' . join(',', map { squote($_) } @$self) . ']';
};


# Remove duplicates
sub normalize {
  my $self = shift;
  @$self = uniq(@$self);
  return $self;
};


# TODO:
#   For the moment, I am not sure where "fields" act
sub to_nodes {
  my ($self, $query) = @_;
  return Krawfish::Result::Node::Fields->new($query, [$self->operations]);
};


1;
