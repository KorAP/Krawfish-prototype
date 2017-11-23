package Krawfish::Koral::Result::Enrich::SortCriterion;
use strict;
use warnings;
use Role::Tiny::With;

with 'Krawfish::Koral::Result::Inflatable';

# Smilar to Snippet, this will add the surface information
# for all sorting criteria to make sorting possible for
# cluster sorting.

# sortedBy : [
#   {
#     "@type" : "koral:field"
#     ...
#   },
#   {
#     "@type" : "koral:string"
#     ...
#   }
# ]


sub new {
  my $class = shift;
  bless { field => shift }, $class;
};


sub to_koral_fragment {
  ...
};


# Stringification
sub to_string {
  my ($self, $id) = @_;
  my $str = 'criterion:[' . $self->{field}->to_string($id);
  return $str.']';
};


# Inflate term ids to terms
sub inflate {
  ...
};

1;
