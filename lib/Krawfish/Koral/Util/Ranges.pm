package Krawfish::Koral::Util::Ranges;
use Krawfish::Koral::Corpus::DateRange;
use Role::Tiny;
use Krawfish::Log;
use strict;
use warnings;

use constant DEBUG => 0;

# TODO:
#   Rename to 'RangeNormalized', and 'BooleanNormalized' etc.

# TODO:
#   [2--6]|3 -> [2--6]
#   [2--6]&3 -> 3

# TODO:
#   The relation with AND needs to be defined as well
#   [2--6] && [3-4] -> [3--4]


# TODO:
#   Combine AND-constraints on the same relational key
#   to range queries, e.g.
#     date > 2014-03-01 & date <= 2017-02
#     to
#     date in [2014-03-01[--2017-02]]
#
#     length >= 5 & length < 2
#     to
#     length in [[5--]2]
#
#     The inner brackets mark inclusivity or exclusivity

# TODO:
#   Maybe positive ranges should have a precedence
#   to negative ranges


# Form date ranges for relational date
# queries like
#   pubDate>2015 & pubDate<2017
# and then normalize date ranges
sub _merge_to_date_ranges {
  my $self = shift;

  print_log('kq_range', ': Merge to date ranges ' . $self->to_string) if DEBUG;

  return if $self->is_nowhere || $self->is_anywhere;

  # Keep track of changes
  my $changes = 0;

  my $ops = $self->operands_in_order;

  return if $self->operation ne 'and';

  for (my $i = 1; $i < scalar(@$ops); $i++) {

    my ($op_a, $op_b) = ($ops->[$i-1], $ops->[$i]);

    # Both operands are fields
    next unless $op_a->is_leaf && $op_b->is_leaf;

    # Both operands require to be dates
    next unless $op_a->key_type eq $op_b->key_type && $op_a->key_type eq 'date';

    # Both operands require the same key
    next unless $op_a->key eq $op_b->key;

    my ($dr, $neg);

    # [a..b] or ![a..b]
    if ($op_a->match eq 'gt' && $op_b->match eq 'lt') {
      $dr = Krawfish::Koral::Corpus::DateRange->new(
        $op_a,
        $op_b
      );
      if ($op_a->value_gt($op_b)) {
        print_log('kq_range', 'Negate daterange') if DEBUG;
        $neg = 1;
      };
    }

    # [b..a] or ![b..a]
    elsif ($op_a->match eq 'lt' && $op_b->match eq 'gt') {
      $dr = Krawfish::Koral::Corpus::DateRange->new(
        $op_b,
        $op_a
      );
      if ($op_b->value_gt($op_a)) {
        print_log('kq_range', 'Negate daterange!') if DEBUG;
        $neg = 1;
      };
    };

    if ($dr) {
      print_log('kq_range', 'Merge ' . $op_a->to_string . ' and ' . $op_b->to_string .
                  ' to ' . $dr->to_string) if DEBUG;

      if ($neg) {
        $dr->is_negative(1);
        print_log('kq_range', 'DateRange is now negative ' . $dr->to_string) if DEBUG;
      };

      $ops->[$i-1] = $dr->normalize;
      splice @$ops, $i, 1;
      $i--;
      $changes++;
    };
  };

  return unless $changes;

  $self->operands($ops);
  return $self;
};


# Check if term strings are already subsumed by other termranges
# 2005[ and 2005-11] -> 2005[
# This is okay, but way slower than a direct daterange merge
# But it should only be done in finalize(), not normalize()

# Merge date ranges that are subsumptions
#   [2--6]|[3--5] -> [2--6]
#   [2--6]&[3--5] -> [3--5]
#   [2--7]|[4--9] -> [2--9]
#   [2--7]&[4--9] -> [4--7]

# TODO:
#   2015&[12-01-2015--20-01-2015] -> 2015

sub _resolve_date_subsumption {
  my $self = shift;

  if (DEBUG) {
    print_log('kq_range', ': Check dates for subsumption for ' . $self->to_string);
  };

  return if $self->is_nowhere || $self->is_anywhere;

  # Keep track of changes
  my $changes = 0;

  my $ops = $self->operands_in_order;

  # TODO:
  #   The relation with AND needs to be defined as well
  #   2014] && 2014[ -> 2014]
  return if $self->operation ne 'or';

  # Iterate over all operands
  for (my $i = 1; $i < scalar(@$ops); $i++) {

    my ($op_a, $op_b) = ($ops->[$i-1], $ops->[$i]);

    # Both operands are fields
    next unless $op_a->is_leaf && $op_b->is_leaf;

    # Both operands require the same key
    next unless $op_a->key eq $op_b->key;

    # Both operands require to be datestrings
    # DateString subsumption
    if ($op_a->key_type eq $op_b->key_type && $op_a->key_type eq 'date_string') {

      my $is_part_of = $op_a->is_part_of($op_b);

      if (DEBUG) {
        print_log('kq_range', 'Compare ' . $op_a->to_string . ' and ' . $op_b->to_string);
      };

      # 2005[ | 2015-10[
      if ($is_part_of == 1) {

        if (DEBUG) {
          print_log('kq_range', 'A: ' . $op_a->to_string . ' is part of ' . $op_b->to_string);
        };

        # Remove b
        splice @$ops, $i, 1;
        $i--;
        $changes++;
      }

      # 2005-10[ | 2015[
      elsif ($is_part_of == -1) {

        if (DEBUG) {
          print_log('kq_range', 'B: ' . $op_b->to_string . ' is part of ' . $op_a->to_string);
        };

        # Remove a
        splice @$ops, $i-1, 1;
        $i-=2; # May merge with the one before
        $changes++;
      };
    }

    # Check if there are dates to join
    elsif ($op_a->key_type && $op_b->key_type &&
             $op_a->key_type eq $op_b->key_type &&
             $op_a->key_type eq 'date') {

      # One parameter is a field
      if ($op_a->type eq 'field') {

        if (DEBUG) {
          print_log('kq_range', 'Make date query to date range');
        };

        $op_a->is_inclusive(1);
        $op_a = Krawfish::Koral::Corpus::DateRange->new(
          $op_a,
          $op_a
        );

      };

      # Check for ranges exclusively
      if ($op_a->type eq 'range' && $op_b->type eq 'range') {

        # Check join operation
        # TODO:
        #   For the moment this ignores negativity
        #   of operators completely
        my $join = $op_a->join_with($op_b);

        # There is a join on ranges possible
        if ($join) {

          if (DEBUG) {
            print_log(
              'kq_range',
              'Join ' . $op_a->to_string . ' and ' . $op_b->to_string .
                ' to ' . $join->to_string);
          };

          splice @$ops, $i-1, 2, $join;
          $i-=1;
          $changes++;
        };
      };
    };
  };

  return unless $changes;

  $self->operands($ops);
  return $self;
};


#   pubDate>2015
#   pubDate<=2014-11-12
sub _create_open_date_ranges {
  my $self = shift;

  print_log('kq_range', ': Create open date ranges') if DEBUG;

  return if $self->is_nowhere || $self->is_anywhere;

  # Keep track of changes
  my $changes = 0;

  # Operand order is irrelevant
  my $ops = $self->operands;

  # Iterate over all operands
  for (my $i = 0; $i < scalar(@$ops); $i++) {

    my $op = $ops->[$i];

    # Operand is no field
    next if $op->type ne 'field';

    # Operand is no date
    next if $op->key_type ne 'date';

    # Open to lower
    if ($op->match eq 'lt') {
      if (DEBUG) {
        print_log('kq_range', 'Create open date range for ' . $op->to_string);
      };

      $ops->[$i] = Krawfish::Koral::Corpus::DateRange->new(
        Krawfish::Koral::Corpus::Field::Date->new($op->key)->minimum->is_inclusive(1),
        $op
      )->normalize;

      $changes++;
    }

    # Open to greater
    elsif ($op->match eq 'gt') {
      if (DEBUG) {
        print_log('kq_range', 'Create open date range for ' . $op->to_string);
      };

      $ops->[$i] = Krawfish::Koral::Corpus::DateRange->new(
        $op,
        Krawfish::Koral::Corpus::Field::Date->new($op->key)->maximum->is_inclusive(1),
      )->normalize;

      $changes++;
    };
  };

  return unless $changes;

  $self->operands($ops);
  return $self;
};


1;
