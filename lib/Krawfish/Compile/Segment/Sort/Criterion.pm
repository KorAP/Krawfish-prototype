package Krawfish::Compile::Segment::Sort::Criterion;
use Krawfish::Util::String qw/binary_short/;
use Krawfish::Log;
use strict;
use warnings;
use Role::Tiny;

use constant DEBUG => 0;

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
      'c_s_crit',
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
      print_log('c_s_crit', 'No match found requested by ' . ref($self));
    };
    return;
  };

  if (DEBUG) {
    print_log(
      'c_s_crit',
      'Current match is ' . $match->to_string .
        ' requested by ' . ref($self)
      );
  };

  # Add criteria
  $self->add_criteria_to($match);

  $self->{match} = $match;

  return $match;
};


# Add criteria
sub add_criteria_to {
  my ($self, $match) = @_;

  my $criterion;

  # Reuse already found criterion
  # TODO:
  #   This only works for field sorting!
  #   So probably check sort_by!
  my $rank;
  if ($match->doc_id == $self->{last_doc_id}) {

    if (DEBUG) {
      print_log('c_s_crit', 'Criterion is identical to last doc' );
    };

    $criterion = $self->{last_criterion};
    $rank = $self->{last_rank};
  }

  # Get criterion again
  else {

    # Get rank
    # TODO:
    #   This information however may not be relevant, as the criteria
    #   can fetched for every matches again!
    $rank = $match->rank($self->level);

    # 1. Take the rank of the match
    if ($rank == 0) {

      if (DEBUG) {
        print_log(
          'c_s_crit',
          'Fetch rank for ' . $match->doc_id .
        ' on l=' . $self->level);
      };

      $rank = $self->criterion->rank_for($match->doc_id);
    };

    # Rank is identical to last rank
    if ($self->{last_rank} && $rank == $self->{last_rank}) {

      if (DEBUG) {
        print_log(
          'c_s_crit',
          "Rank is identical to last rank $rank on l=" . $self->level
        );
      };

      $criterion = $self->{last_criterion};
    }

    # 2. Check, if the rank is equal to max_rank + 1
    #    (meaning no criterion)
    elsif ($rank <= $self->criterion->max_rank) {

      if (DEBUG) {
        print_log(
          'c_s_crit',
          "Fetch sort key from rank $rank on l=" . $self->level .
            '; max=' . $self->criterion->max_rank
        );
      };

      # 3. Otherwise get the nth value from the
      #    sorted rank field can either be a
      #    number or a comparation value
      $criterion = $self->criterion->key_for($rank);

      if (!defined $criterion) {
        print_log(
          'c_s_crit',
          'WARN: No key found for rank ' .
            $rank . ' on level ' .
            $self->level);
      };
    }
    elsif (DEBUG) {
      if (DEBUG) {
        print_log('c_s_crit', 'Rank means there is no value for the field given');
      };
    };
  };

  # Set criterion
  $match->sorted_by->criterion($self->level => $criterion);

  # Create criterion
  $self->{last_rank} = $rank;
  $self->{last_criterion} = $criterion;
  $self->{last_doc_id} = $match->doc_id;

  if (DEBUG) {
    print_log(
      'c_s_crit',
      "Add criterion " . binary_short($criterion) . " at level " . $self->level .
        ' in ' . ref($self)
      );
  };

  # Add criteria for deeper levels
  if (Role::Tiny::does_role($self->{query}, 'Krawfish::Compile::Segment::Sort::Criterion')) {
    $self->{query}->add_criteria_to($match);
  };
};

1;
