package Krawfish::Compile::Segment::Sort::Criterion;
use Krawfish::Log;
use strict;
use warnings;
use Role::Tiny;

use constant DEBUG => 1;

# TODO:
#   On the segment level, it's enough to compare on the ranks,
#   but it's also necessary to enrich with the fields
#   to have the necessary enrichment when moving to the cluster
#   (at least having the collation comparation key).
#   To make this work in multivalued fields, the fields
#   would
#
#     a) need to be sorted in alphabetic or numeric order
#     b) the ranking sorted field is indexed

# TODO:
#   This may very well be in Krawfish::Compile::Enrich::SortCriterion;

# TODO:
#   This currently only works for fields!


# Implement new current match
sub current_match {
  my $self = shift;

  if (DEBUG) {
    print_log(
      'criterion',
      'Get current match as ' . ref($self),
      '  Current is ' .
        ($self->{current} ? $self->{current}->to_string : '???')
    );
  };

  return $self->{match} if $self->{match};

  unless ($self->{current}) {
    warn 'No current defined!';
    return;
  };

  my $match = $self->match_from_posting($self->{current});

  unless ($match) {
    if (DEBUG) {
      print_log('criterion', 'No match found requested by ' . ref($self));
    };
    return;
  };

  if (DEBUG) {
    print_log(
      'criterion',
      'Current match is ' . $match->to_string .
        ' requested by ' . ref($self)
      );
  };

  # Add criteria
  $self->add_criteria($match);

  $self->{match} = $match;

  return $match;
};


# Add criteria
sub add_criteria {
  my ($self, $match) = @_;

  my $criterion;

  # Reuse already found criterion
  # TODO:
  #   This only works for field sorting!
  #   So probably check sort_by!
  if ($match->doc_id == $self->{last_doc_id}) {
    $criterion = $self->{last_criterion};
  }

  # Get criterion again
  else {

    # Get rank
    # TODO:
    #   This information however may not be relevant, as the criteria
    #   can fetched for every matches again!
    my $rank = $match->rank($self->level);

    # 1. Take the rank of the match
    if ($rank == 0) {
      $rank = $self->criterion->rank_for($match->doc_id);
    };

    # 2. Check, if the rank is equal to max_rank + 1
    #    (meaning no criterion)
    if ($rank == $self->max_rank) {
      $criterion = '0';
    }

    # 3. Otherwise get the nth value from the sorted rank field
    #    can either be a number or a comparation value
    else {
      $criterion = '*';
    };
  };

  # Set criterion
  $match->sorted_by->criterion($self->level => $criterion);

  # Create criterion
  $self->{last_criterion} = $criterion;
  $self->{last_doc_id} = $match->doc_id;

  if (DEBUG) {
    print_log(
      'criterion',
      "Add criterion $criterion at level " . $self->level .
        ' in ' . ref($self)
      );
  };

  # Add criteria for deeper levels
  if (Role::Tiny::does_role($self->{query}, 'Krawfish::Compile::Segment::Sort::Criterion')) {
    $self->{query}->add_criteria($match);
  };
};

1;
