package Krawfish::Koral::Util::Sequential;
use Krawfish::Log;
use Krawfish::Query::Nothing;
use Krawfish::Query::Constraint::Position;
use Krawfish::Query::Constraints;
use List::MoreUtils qw!uniq!;
use strict;
use warnings;

use constant {
  DEBUG => 1,
    NULL => 0,
    POS => 1,
    OPT => 2,
    NEG => 3,
    NOP => 4,
    ANY => 5,
    TYPE  => 0,
    FREQ  => 1,
    QUERY => 2
};

# TODO:
#   Resolve optionality!
#   And keep in mind that the optional anchor may in fact be
#   the filterable query!
#
# The filter is only necessary at the top element of one anchor


# Normalize query and check for anchors
sub normalize {
  my $self = shift;

  my $ops = $self->operands;

  # First pass - mark anchors
  my @problems = ();
  for (my $i = 0; $i < @$ops; $i++) {

    # Operand in question
    my $op = $ops->[$i];

    # Sequences are no constraints!
    if ($op->type eq 'sequence') {

      # TODO:
      #   This currently ignores negative sequences

      # Replace operand with operand list
      splice @$ops, $i, 1, @{$op->operands};
    };

    # Operand can be ignored
    if ($op->is_null) {
      splice @$ops, $i, 1;
      $i--;
      next;
    }

    # One operand can't match
    elsif ($op->is_nothing) {
      return $self->builder->nothing;
    };

    # Normalize operands
    $ops->[$i] = $ops->[$i]->normalize;

    # Push to problem array
    unless ($op->maybe_anchor) {
      push @problems, $i;
    };
  };


  # No operands left
  unless (scalar @$ops) {

    # Return null query
    return $self->builder->null->normalize;
  }

  # This is a single operand sequence
  elsif (scalar @$ops == 1) {

    # Constraints can be ignored
    return $self->operands->[0]->normalize;
  }

  # Query is not answerable
  elsif (scalar @$ops == scalar @problems) {
    $self->error(613, 'Sequence has no anchor operand');
    return;
  };

  # Store operands
  $self->operands($ops);

  # TODO:
  # Simplify repetitions
  # $self = $self->_reslove_consecutive_repetitions;

  # There are no problems
  return $self unless @problems;

  # Remember problems
  $self->{_problems} = 1;
  return $self;
};



# TODO:
#   See t/koral/sequential.t
sub _resolve_consecutive_repetitions {
  my $self = shift;

  my $ops = $self->operands;

  # Second pass - resolve simple consecutive operands
  for (my $i = 0; $i < @$ops; $i++) {

    my ($op1, $op2, $op1_min, $op1_max, $op2_min, $op2_max) = ();
    if ($ops->[$i-1]->type eq 'repetition') {
      my $preceding = $ops->[$i-1];
      $op1 = $preceding->span->to_string;
      $op1_min = $preceding->min;
      $op1_max = $preceding->max;
    }
    else {
      $op1 = $ops->[$i-1]->to_string;
    };

    if ($ops->[$i]->type eq 'repetition') {
      my $this = $ops->[$i];
      $op2 = $this->span->to_string;
      $op2_min = $this->min;
      $op2_max = $this->max;
    }
    else {
      $op2 = $ops->[$i]->to_string;
    };
  };

  return $self;
  ...
};


# TODO:
# In finalize check, if there is at least one non-optional anchor
# sub finalize

sub has_problems {
  return $_[0]->{_problems};
};


# Optimize
# TODO:
#   The second operand in constraint queries should probably be less frequent,
#   because it needs to be buffered! Another thing to keep in mind is the complexity
#   regarding payloads, so an additional feature for costs may be useful!
# TODO:
#   remember filter flag!!!
sub optimize {
  my ($self, $index) = @_;

  print_log('kq_sequtil', 'Optimize sequence') if DEBUG;

  # Length of operand size with different types
  # Stores values as [TYPE, FREQ, QUERY]
  my @queries;

  # Remember the least common non-optional positive query
  my $filterable_query;

  # Classify all operands into the following groups:
  #   POS: positive operand (directly queriable)
  #   OPT: optional operand
  #   NEG: negative operand
  #   NOP: negative optional operand
  #   ANY: any query
  my $ops = $self->operands;
  for (my $i = 0; $i < $self->size; $i++) {

    my $op = $ops->[$i];

    # Query matches anywhere
    if ($op->is_any) {
      $queries[$i] = [ANY, -1, $op];
    }

    # Is negative operand
    elsif ($op->is_negative) {

      # Directly collect negative queries
      my $query = $ops->[$i]->optimize($index);
      my $freq = $query->freq;

      # Negative operand can't occur - rewrite to any query, but
      # keep quantities intact (i.e. <!s> can have different length than [!a])
      if ($query->freq != 0) {

        if ($op->is_optional) {
          $queries[$i] = [NOP, $freq, $query];
        }
        else {
          $queries[$i] = [NEG, $freq, $query];
        }
      }
      else {
        if (DEBUG) {
          print_log('kq_sequtil', 'Negative query ' . $query->to_string . ' never occurs');
        };

        # Treat non-existing negative operand as an ANY query
        $queries[$i] = [ANY, -1, $query];
      };
    }

    # Is positive operand
    else {

      # Directly collect positive queries
      my $query = $ops->[$i]->optimize($index);

      # Get frequency of operand
      my $freq = $query->freq;

      # One element matches nowhere - the whole sequence matches nowhere
      return Krawfish::Query::Nothing->new if $freq == 0;

      if (DEBUG) {
        print_log('kq_sequtil', 'Get frequencies for possible anchor ' . $query->to_string);
      };

      # The operand is not optional, so the filter may be applied
      unless ($ops->[$i]->is_optional) {

        # Current query is less common
        if (!defined $filterable_query || $freq < $queries[$filterable_query]->freq) {
          $filterable_query = $_;
        };
        $queries[$i] = [POS, $freq, $query];
      }

      # The operand is optional
      else {
        print_log('kq_sequtil', $query->to_string . ' is optional') if DEBUG;
        $queries[$i] = [OPT, $freq, $query];
      };
    };
  };


  # Set filter flag to less common anchor
  unless (defined $filterable_query) {
    # TODO:
    # If the sequence has no filterable operand, it means,
    # the only anchors are optional, which needs to be taken into account
    # warn 'no filterable query';
  };


  # Group operands
  print_log('kq_sequtil', 'Group ' . $self->size . ' operands') if DEBUG;

  # Secure operations to break
  my $break = $self->size;

  # Join operands, as long as there are more than one
  while (scalar(@queries) > 1) {

    if (DEBUG) {
      print_log('kq_sequtil', 'Sort ' . scalar(@queries) . ' remaining operands');
    };

    my $queries = \@queries;

    # Get the best positive operands available to build a group
    my ($index_a, $index_b) = _get_best_pair($queries);

    print_log(
      'kq_sequtil', 'Check ' .
      $queries->[$index_a]->[QUERY]->to_string . ' and ' .
        $queries->[$index_b]->[QUERY]->to_string
      ) if DEBUG;


    # Check the distance between the operands
    my $dist = abs($index_a - $index_b);
    print_log('kq_sequtil', 'Distance is ' . $dist) if DEBUG;

    if ($dist <= 2) {

      # Best operands are consecutive
      if ($dist == 1) {

      # Join both operands

        my $query_a = $queries->[$index_a];
        my $query_b = $queries->[$index_b];
        my $new_query;

        # Create a follows directly,
        # because the second operand is buffered and should occur less often
        if ($index_a < $index_b) {
          $new_query = $self->_succeeds_directly($query_b->[QUERY], $query_a->[QUERY]);
        }

        # Create a precedes directly
        else {
          $new_query = $self->_precedes_directly($query_b->[QUERY], $query_a->[QUERY]);
        }

        # Set new query
        $queries->[$index_a] = [POS, $new_query->freq, $new_query];

        # Remove old query
        splice(@$queries, $index_b, 1);

        print_log(
          'kq_sequtil',
          'Queries are consecutive, build query ' . $new_query->to_string
        ) if DEBUG;
      }

      # Check distance between two operands
      elsif ($dist == 2) {
        ...
      };
    };

    if ($break-- < 0) {
      print_log('kq_sequtil', 'EMERGENCY BREAK') if DEBUG;
      return;
    };
  };



  # 1. ---
  #   my ($a, $b) = _rarest_pair;
  #   if (distance($a, $b) > 1) {
  #     GOTO 3;
  #   };
  #
  # 3. Check the rarest pos operand
  #    a) If there is a fixed size (classed) ANY element surrounding, extend,
  #       if there are two, with the one closer to the middle of the sequence (absolute),
  #       or prefer left.
  #         []{3}[a] -> leftExt(a, 3)
  #         {[]{3}}[a] -> leftExt(class=1: a, 3)
  #         [a][]{3} -> rightExt(a, 3)
  #         [a]{[]{3}} -> rightExt(class=1: a, 3)
  #         GOTO 2.
  #    b) If there is a fixed size or optional single NEG element on the left, extend,
  #       if there are two, with the one with the lowest frequency
  #       or with the one closer to the middle of the sequence (absolute),
  #       or prefer left.
  #       (negative elements can't be classed)
  #         [!b][a] -> leftExt(min=1,max=1: exclude(pos=succeedsDirectly,a,b))
  #         [a][!b] -> rightExt(min=1,max=1: exclude(pos=precedessDirectly,a,b))
  #         [!b]?[a] -> leftExt(exclude(pos=succeedsDirectly,a,b), 0, 1)
  #         [a][!b]? -> rightExt(exclude(pos=precedessDirectly,a,b), 0, 1)
  #         GOTO 2.
  #    c) If there is an optional, varying size (classed) ANY element surrounding,
  #       if there are two, with the one with the smallest |max - min| difference,
  #       and closer to the middle of the sequence (absolute)
  #         []{1,3}[a] -> leftExt(a, 1, 3)
  #         {[]{1,3}}[a] -> leftExt(class=1: a, 1, 3)
  #         [a][]{1,3} -> rightExt(a, 1, 3)
  #         [a]{[]{1,3}} -> rightExt(class=1: a, 1, 3)
  #         GOTO 2.
  # ...
  #      If there is a varying non-optional size POS element surrounding,
  #       if there are two, with the rarest,
  #       and closer to the middle of the sequence (absolute)

  return $queries[0]->[QUERY];
};


# Get the query segments based on frequency,
# if even, get the one that is closer to the middle
sub _get_best_pair {
  my $queries = shift;
  my @best = ();
  my $length = scalar @$queries;

  # Iterate over all operands
  for (my $i = 0; $i < $length; $i++) {

    # Operand is not pos
    next unless $queries->[$i]->[TYPE] == POS;

    # The pair is not saturated yet
    if (@best < 2) {

      push @best, $i;

      # Sort the saturated pair
      if (@best == 2) {

        # Check if the best queries are already sorted
        if (_compare($queries, $best[0], $best[1]) == 1) {

          # Otherwise sort them
          my $temp = $best[0];
          $best[0] = $best[1];
          $best[1] = $temp;
        };
      };

      next;
    };

    my $freq = $queries->[$i]->[FREQ];

    # Next query is not among the best
    next if $freq > $queries->[$best[1]]->[FREQ];

    # Is better than first
    if (_compare($queries, $i, $best[0]) == -1) {
      unshift @best, $i;
      $#best = 1;
    }
    elsif (_compare($queries, $i, $best[0]) == -1) {
      $best[1] = $i;
    };
  };

  return @best;
};


# Compare method for two queries
# TODO:
#   This may very well take another parameter indicating the 'closest ally',
#   meaning a possible best operand already chosen, so the next best operand
#   is close to this one.
sub _compare {
  my ($queries, $x, $y) = @_;

  # Get the query frequencies and compare
  # The rarer the better
  my $freq_x = $queries->[$x]->[FREQ];
  my $freq_y = $queries->[$y]->[FREQ];
  if ($freq_x < $freq_y) {

    # x is better
    return -1;
  }

  elsif ($freq_x > $freq_y) {

    # y is better
    return 1;
  };

  # Check, which index value is closer to the middle of the sequence
  # This is just a mild check and should probably rather
  # use the middle of the pos-values
  my $middle = int(scalar(@$queries) / 2);
  if (abs($middle - $x) < abs($middle - $y)) {

    # x is better
    return -1;
  }

  elsif (abs($middle - $x) > abs($middle - $y)) {

    # y is better
    return 1;
  };

  # Return the first value
  return -1;
};


sub _get_middle {
  my ($query_types, $left_index, $right_index) = @_;
  ...
};


sub _compact {
  my ($query_types, $queries) = @_;
  for (my $i = (scalar @$query_types - 1); $i >= 0; $i--) {
    if ($query_types->[$i] == NULL) {
      splice(@$query_types, $i, 1);
      splice(@$queries, $i, 1);
    };
  };
};

# Create raw queries
sub _precedes_directly {
  my ($self, $query_a, $query_b) = @_;

  return Krawfish::Query::Constraints->new(
    [Krawfish::Query::Constraint::Position->new(PRECEDES_DIRECTLY)],
    $query_a,
    $query_b
  );
};


# Create raw queries
sub _succeeds_directly {
  my ($self, $query_a, $query_b) = @_;

  return Krawfish::Query::Constraints->new(
    [Krawfish::Query::Constraint::Position->new(SUCCEEDS_DIRECTLY)],
    $query_a,
    $query_b
  );
};

1;


__END__


  my $last_type;
  my @consecutives;

  for (my $i = ($self->size - 1); $i >= -1; $i--) {

    # Initialize last type
    unless (defined $last_type) {
      $last_type = $query_types[$i]->[0];
      next;
    };

    if (($i >= 0) && ($query_types[$i]->[0] == $last_type)) {

      # Initialize consecutives
      unless (@consecutives) {
        unshift @consecutives, $i+1;
      };
      unshift @consecutives, $i;
    }

    # Types differ - flush
    elsif (scalar @consecutives > 1) {

      # The group consists of positives
      if ($query_types[$consecutives[0]]->[0] == POS) {

        my $first_i = shift @consecutives;
        my $query = $queries[$first_i];

        print_log('kq_sequtil', 'Create query for consecutive positive ops') if DEBUG;

        # Iterate as long as there are consecutives
        while (@consecutives) {

          # Get next from list
          my $next_i = shift @consecutives;

          # Create a precedes directly
          if ($query->freq <= $queries[$next_i]->freq) {

            print_log(
              'kq_sequtil',
              'Freq is '. $query->to_string . ' <= ' .$queries[$next_i]->to_string
            ) if DEBUG;

            $query = $self->_precedes_directly($query, $queries[$next_i]);
          }

          # Reverse the order due to frequency optimization
          else {
            $query = $self->_succeeds_directly($queries[$next_i], $query);
          };

          $queries[$next_i] = undef;
          $query_types[$next_i] = [NULL, 0];
        };

        # Store the newly build query at the first position.
        $queries[$first_i] = $query;

        @consecutives = ();
        $last_type = $i;
      }
      else {
        warn 'Types not supported yet';
      };
    };
  };
