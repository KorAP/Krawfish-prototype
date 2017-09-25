package Krawfish::Koral::Result::Enrich::SortCriteria;
use strict;
use warnings;

# Smilar to Snippet, this will add the surface information
# for all sorting criteria to make sorting possible for
# cluster sorting.

sub new {
  my $class = shift;
  bless [@_], $class;
};


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


sub to_string {
  my $self = shift;
  my $str = 'criteria:[';
  $str .= join(',', map { $_->to_string } @$self);
  return $str.']';
};

sub inflate {
  ...
};

1;
