package Krawfish::Koral::Meta::Aggregate::Facets;
use Krawfish::Util::String qw/squote/;
use List::MoreUtils qw/uniq/;
use strict;
use warnings;

sub new {
  my $class = shift;
  bless [@_], $class;
};

sub type {
  'facets'
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

sub normalize {
  my $self = shift;
  @$self = uniq(@$self);
  return $self;
};


sub to_string {
  my $self = shift;
  return 'facets:[' . join(',', map { squote($_) } @$self) . ']';
};

1;
