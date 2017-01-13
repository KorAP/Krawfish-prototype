package Krawfish::Result::Limit;
use Krawfish::Log;
use strict;
use warnings;

use constant DEBUG => 0;

# Group snippets based on certain criteria, for example:
# metadata!
# - this is an extension to facets, where snippets are grouped
#   based on a certain facet.
# - having facets in a first step may improve the distributed aggregation
#   (as the central node than knows, which facets are most or least common)
# - this grouping doesn't seem beneficial - as the facet view already helps here
#
# innertextual!
# - has a certain identical class on surface
# - has the same starting characters of a word
# - has the same ending characters of a word
# - has the same POS of a certain class (this is actually pretty hard!)
#   - this may mean to modify the search a bit to lift the posting types
#     and make a class, like [orth=der & base/p=*]
#   - At least the postingslist of base/p=* should be merged in parallel!
#
# This is already possible in C2 so it needs to be implemented!

# A group has the following structure:
# {
#   criterion => [freq, doc_freq]
# }
# Where criterion may be a sequence of criteria
# with class information, like
#   1:der|2:Baum => []

# Construct grouping function
sub new {
  my $class = shift;
  bless {
    query => shift,

    # This is a group criterion object, created outside, that defines the criterion
    criterion => shift,
    classes => [@_],

    # Group to fill with matches and group info
    # (as class1=>X, class2=>Y)
    groups => {}
  }, $class;
};

# Go through all matches
# This could, nonetheless, be implemented like Facets ...
sub _init {
  my $self = shift;
  my $criterion = $self->{criterion};
  my $query = $self->{query};

  my %groups = ();
  my $group, $current;
  my $doc_id = -1;

  while ($query->next) {

    $current = $query->current or last;

    # Potentially create new group
    $group = ($groups{$criterion->get_group($current)} //= [0,0]);

    # Increment freq
    $group->[0]++;

    if ($current->doc_id != $doc_id) {

      # Increment doc_freq
      $group->[1]++;

      $doc_id = $current->doc_id;
    };
  };

  return \%groups;
};

sub next {
  my $self = shift;


  return $criterion->groups;
};


sub current {
  $_[0]->{query}->current;
}


# May return a hash reference with information
sub current_group;


sub to_string {
  my $self = shift;
  my $str = 'collectGroups(';
  $str .= $self->{criterion}->to_string . ':';
  $str .= $self->{query}->to_string;
  $str .= ')';
};

1;
