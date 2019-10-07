package Krawfish::Koral::Compile::Group::Joined;
use Krawfish::Koral::Compile::Node::Group::Joined;
use strict;
use warnings;

# TODO:
#   Remember order of fields

# Criteria are passed like this:
# "group" : {
#   "@type" : "compile:group",
#   "criteria" : [
#     {
#       "@type" : "group:field",
#       "key" : "author"
#     },
#     {
#       "@type" : "group:queryClass",
#       "nr" : 4
#     }
#   ]
# }

# Accept Criteria
sub new {
  my $class = shift;
  bless [@_], $class;
}

sub type {
  'joined'
}

sub normalize {
  # Group all criteria, so that Criterion::Field gets a list of
  # multiple fields, classes get multiple numbers etc.

  # Order the criterion strictly as:
  # group[fields["author","age"],queryClass[4,2]] etc.

  # Remember the order of the results as:
  # [0,2,3,1]
  # Meaning that the first column in the pattern will be put in the first
  # position in the result, the second in the third and so forth
  # All criteria themselves will have a similar internal sorting.
}
