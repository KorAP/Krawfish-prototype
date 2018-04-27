package Krawfish::Koral::Util::Ranges;
use Krawfish::Koral::Corpus::DateRange;
use Role::Tiny;
use Krawfish::Log;
use strict;
use warnings;

use constant DEBUG => 1;

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
        $dr = $dr->is_negative(1);
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


#   pubDate>2015
#   pubDate<=2014-11-12
sub _create_date_ranges {
  ...
};


1;
