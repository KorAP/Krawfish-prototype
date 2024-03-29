package Krawfish::Koral::Util::Sequential;
use strict;
use warnings;
use Role::Tiny;
use Krawfish::Log;
use Krawfish::Query::Nowhere;
use Krawfish::Query::Extension;
use Krawfish::Query::Constraint::Position;
use Krawfish::Query::Constraint::InBetween;
use Krawfish::Query::Constraint::ClassBetween;
use Krawfish::Query::Constraint;
use List::MoreUtils qw!uniq!;

use constant {
  DEBUG  => 0,
  NULL   => 0,
  POS    => 1,
  OPT    => 2,
  NEG    => 3,
  ANY    => 5,
  TYPE   => 0,
  FREQ   => 1,
  QUERY  => 2,
  KQUERY => 3
};

with 'Krawfish::Koral::Report';

# TODO:
#   Resolve optionality!
# The filter is only necessary at the top element of one anchor

# TODO:
#   Simplify sequences in boolean form, like
#   der alte Baum | der junge Baum -> der (alte|junge) Baum

# Normalize query and check for anchors
sub normalize {
  my $self = shift;

  print_log('kq_sequtil', 'Normalize query ' . $self->to_string) if DEBUG;

  my $ops = $self->operands;

  print_log('kq_sequtil', '1st pass - flatten and mark anchors') if DEBUG;

  # First pass - mark anchors
  my $problems = 0;
  for (my $i = 0; $i < @$ops; $i++) {

    # Operand in question
    my $op = $ops->[$i];

    print_log('kq_sequtil', 'Check operand in sequence ' . $op->to_string) if DEBUG;

    # Sequences are no constraints!
    if ($op->type eq 'sequence') {

      print_log('kq_sequtil', 'Flatten embedded sequence ' . $op->to_string) if DEBUG;

      # TODO:
      #   This currently ignores negative sequences

      # Replace operand with operand list
      splice @$ops, $i, 1, @{$op->operands};
      redo;
    };

    # Operand can be ignored
    if ($op->is_null) {
      splice @$ops, $i, 1;
      $i--;
      CORE::next;
    }

    # One operand can't match
    elsif ($op->is_nowhere) {
      return $self->builder->nowhere;
    };

    # Normalize operands
    my $new_op = $op->normalize;

    # New op can't be normalized, for example it is a
    # classed sequence of any-operators
    if (!$new_op) {

      if (DEBUG) {
        print_log('kq_sequtil', 'Operand ' . $op->to_string . ' is not normalizable');
        print_log('kq_sequtil', 'Strip potential classes');
      };

      # First unpack classes
      my @classes = ();
      while ($op->type eq 'class') {
        push @classes, $op->number;
        $op = $op->operand;
      };

      # Operand matches somehow anywhere
      # This can be the case with something like {1:[]{2:[]}}
      if ($op->is_anywhere) {

        if (DEBUG) {
          print_log('kq_sequtil', 'Query matches anywhere ' . $op->to_string);
        };

        my $qb = $self->builder;

        # Create anywhere span
        $new_op = $qb->repeat(
          $qb->anywhere,
          $op->min_span,
          $op->max_span
        );

        # Readd classes
        foreach (@classes) {
          $new_op = $qb->class($new_op, $_);
        };

        # A minor warning that we cheated
        $self->warning(
          000,
          'Nested classes in empty token sequences are not yet supported',
          $op->to_string
        );
      }

      # I don't know when this could happen ...
      else {
        $self->error(000, 'Subsequence is not normalizable', $op->to_string);
        return;
      };

      # Normalize newly build query
      $new_op = $new_op->normalize;
    };

    $ops->[$i] = $new_op;

    # Push to problem array
    unless ($op->maybe_anchor) {
      print_log('kq_sequtil', 'Operand is no anchor: ' . $op->to_string) if DEBUG;
      $problems++;
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
  elsif (scalar @$ops == $problems) {

    # TODO:
    #   Query may have very well multiple optional query operands
    $self->error(613, 'Sequence has no anchor operand');
    return;
  };

  # Store operands
  $self->operands($ops);

  print_log('kq_sequtil', 'Sequence has ' . ($problems+0) . ' problems') if DEBUG;

  $self = $self->_join_consecutive_operands;

  # Remember problems
  $self->{_problems} = 1 if $problems;
  return $self;
};


# TODO:
#   See t/koral/query/sequential.t
sub _join_consecutive_operands {
  my $self = shift;

  if (DEBUG) {
    print_log(
      'kq_sequtil',
      '2nd pass - join consecutive operands in ' . $self->to_string
    );
  };

  my $ops = $self->operands;

  # Second pass - resolve simple consecutive operands
  for (my $i = 1; $i < @$ops; $i++) {

    my ($op1, $op2) = ();
    my ($op1_min, $op1_max, $op2_min, $op2_max) = (1,1,1,1);

    if ($ops->[$i-1]->type eq 'repetition') {
      my $preceding = $ops->[$i-1];
      $op1 = $preceding->operand;
      $op1_min = $preceding->min;
      $op1_max = $preceding->max;
    }
    else {
      $op1 = $ops->[$i-1];
    };

    if ($ops->[$i]->type eq 'repetition') {
      my $this = $ops->[$i];
      $op2 = $this->operand;
      $op2_min = $this->min;
      $op2_max = $this->max;
    }
    else {
      $op2 = $ops->[$i];
    };

    # TODO:
    #   Hash may be better than string
    if ($op1->to_signature eq $op2->to_signature) {
      if (DEBUG) {
        print_log(
          'kq_sequtil',
          "Compare 2x " . $op1->to_string .
            " with $op1_min,$op1_max and $op2_min,$op2_max"
        );
      };

      my $new_op = $self->builder->repeat(
        $op1,
        $op1_min + $op2_min,
        $op1_max + $op2_max
      );

      # Replace operand with operand list
      splice @$ops, $i-1, 2, $new_op->normalize;
      $i--;
    };
  };

  return $self;
};


# TODO:
# In finalize check, if there is at least one non-optional anchor
# sub finalize;


sub has_problems {
  return $_[0]->{_problems};
};


# Optimize the query
sub optimize {
  my ($self, $segment) = @_;

  unless ($segment) {
    print_log('kq_sequtil', 'Segment undefined - ABORT');
    return;
  };

  # The second operand in constraint queries should probably be less frequent,
  # because it needs to be buffered! Another thing to keep in mind is the complexity
  # regarding payloads, so an additional feature for costs may be useful!

  print_log('kq_sequtil', 'Optimize sequence') if DEBUG;

  # Length of operand size with different types
  # Stores values as [TYPE, FREQ, QUERY, KQUERY]
  my @queries;

  # Remember the least common non-optional positive query
  # my $filterable_query;

  # Classify all operands into the following groups:
  #   POS: positive operand (directly queriable)
  #   OPT: optional operand
  #   NEG: negative operand
  #   ANY: anywhere query
  my $ops = $self->operands;
  for (my $i = 0; $i < $self->size; $i++) {

    my $op = $ops->[$i];

    # Operand matches anywhere
    if ($op->is_anywhere) {
      $queries[$i] = [ANY, -1, undef, $op];

      if (DEBUG) {
        print_log(
          'kq_sequtil',
          'Operand matches anywhere ' . $op->to_string
        );
      }
    }

    # Operand is negative
    elsif ($op->is_negative) {
      $queries[$i] = [NEG, -1, undef, $op];

      if (DEBUG) {
        print_log(
          'kq_sequtil',
          'Operand is negative ' . $op->to_string
        );
      }
    }

    # Operand is positive
    else {

      if (DEBUG) {
        print_log(
          'kq_sequtil',
          'Operand is positive ' . $op->to_string
        );
      }

      # The operand is not optional, so the filter may be applied
      unless ($op->is_optional) {

        # Directly collect positive queries
        my $query = $op->optimize($segment);

        if (DEBUG) {
          print_log(
            'kq_sequtil',
            'Get frequencies for possible anchor ' . $query->to_string
          );
        };

        # Get frequency of operand
        my $freq = $query->max_freq;

        # One element matches nowhere - the whole sequence matches nowhere
        return Krawfish::Query::Nowhere->new if $freq == 0;

        # Current query is less common
        # if (!defined $filterable_query ||
        #   $freq < $queries[$filterable_query]->max_freq) {
        #  $filterable_query = $_;
        #};
        $queries[$i] = [POS, $freq, $query, $op];
      }

      # The operand is optional
      else {
        print_log(
          'kq_sequtil',
          $op->to_string . ' is optional'
        ) if DEBUG;
        $queries[$i] = [OPT, -1, undef, $op];
      };
    };
  };


  # Set filter flag to less common anchor
  # unless (defined $filterable_query) {
    # TODO:
    # If the sequence has no filterable operand, it means,
    # the only anchors are optional, which needs to be taken into account
    # warn 'no filterable query';
  # };


  # Group operands
  print_log('kq_sequtil', 'Group ' . $self->size . ' operands') if DEBUG;

  # Secure operations to break
  my $break = $self->size;

  if (DEBUG) {
    my @list;
    foreach (@queries) {
      if ($_->[TYPE] == POS) {
        push @list, '+';
      }
      elsif ($_->[TYPE] == OPT) {
        push @list, '?';
      }
      elsif ($_->[TYPE] == NEG) {
        push @list, '-';
      }
      elsif ($_->[TYPE] == ANY) {
        push @list, '*';
      };
    };

    print_log('kq_sequtil', 'Combine ' . join('', map { "[$_]" } @list));
  };


  # Join operands, as long as there are more than one
  while (scalar(@queries) > 1) {

    if (DEBUG) {
      print_log(
        'kq_sequtil',
        'Sort ' . scalar(@queries) . ' remaining operands'
      );
    };

    my $queries = \@queries;

    # Get the best positive operands available to build a group
    my ($index_a, $index_b) = _get_best_pair($queries);

    # Check the distance between the operands
    my $dist = defined $index_b ? abs($index_a - $index_b) : 0;

    if (DEBUG) {
      my $str = 'Check ';
      $str .= $queries->[$index_a]->[QUERY]->to_string;
      $str .= ' and ' . $queries->[$index_b]->[QUERY]->to_string if defined $index_b;
      print_log('kq_sequtil', $str);

      print_log('kq_sequtil', 'Distance is ' . $dist);
    };


    # Best operands are consecutive
    if ($dist == 1) {

      # Combinde positives
      _combine_pos($queries, $index_a, $index_b);

      # Go to next combination
      CORE::next;
    }

    # Check distance between two operands
    #
    elsif ($dist == 2) {

      # Check order
      my $index_between = $index_a < $index_b ? $index_a + 1 : $index_a - 1;

      # a) If there is an optional, variable, classed ANY operand
      #    in between, make a distance query

      # The inbetween is ANY
      if ($queries->[$index_between]->[TYPE] == ANY) {
        _combine_anywhere($queries, $index_a, $index_b, $index_between);
        CORE::next;
      }

      # b) If there is an optional, variable, classed NEG operand
      #    in between, make a not_between query

      # The inbetween is NEGATIVE
      elsif ($queries->[$index_between]->[TYPE] == NEG) {
        _combine_neg($queries, $index_a, $index_b, $index_between, $segment);
        CORE::next;
      };

      print_log('kq_sequtil', 'Can\'t combine ANY or NEG operands') if DEBUG;
    };

    # Matches are too far away or there is no index_b
    # Extend with surrounding operands
    if (DEBUG) {
      print_log('kq_sequtil', 'Extend anchor operand with surrounding');
    };

    # Get surrounding queries
    my $surr_l = $index_a - 1;
    my $surr_r = $index_a + 1;
    my $surr_l_query = $surr_l >= 0 ? $queries->[$surr_l] : undef;
    my $surr_r_query = $surr_r < scalar(@$queries) ? $queries->[$surr_r] : undef;

    if (DEBUG) {
      if ($surr_l_query) {
        print_log(
          'kq_sequtil',
          'Left operand is ' . $surr_l_query->[KQUERY]->to_string
        );
      };

      if ($surr_r_query) {
        print_log(
          'kq_sequtil',
          'Right operand is ' . $surr_r_query->[KQUERY]->to_string
        );
      };
    };

    my $surr_i;
    my $new_query;

    # c) If there is an optional, variable, classed OPT operand
    #    make an extension
    #    e.g. [aa]?[bb]
    if (($surr_l_query && $surr_l_query->[TYPE] == OPT) ||
          ($surr_r_query && $surr_r_query->[TYPE] == OPT)) {
      _extend_opt($queries, $index_a, $index_b, $segment);
      CORE::next;
    }

    # x) If there is an optional, variable, classed ANY operand
    #    make an extension
    #    e.g. []{2,3}[bb]
    elsif (($surr_l_query && $surr_l_query->[TYPE] == ANY) ||
          ($surr_r_query && $surr_r_query->[TYPE] == ANY)) {
      _extend_any($queries, $index_a, $index_b, $segment);
      CORE::next;
    }

    # d) If there is a varying non-optional size POS element surrounding,
    #    create a sequence.
    #    if there are two, with the rarest,
    #    and closer to the index_b, or closer to the middle
    elsif (($surr_l_query && $surr_l_query->[TYPE] == POS) ||
          ($surr_r_query && $surr_r_query->[TYPE] == POS)) {

      # Both surrounding types are POS
      if ($surr_l_query && $surr_r_query &&
            ($surr_l_query->[TYPE] == $surr_r_query->[TYPE])) {

        # Left index is best
        if ($surr_l_query->[FREQ] < $surr_r_query->[FREQ]) {
          $surr_i = $surr_l;
        }

        # Right index is best
        elsif ($surr_l_query->[FREQ] > $surr_r_query->[FREQ]) {
          $surr_i = $surr_r;
        }

        # Take the one closer to index_b
        elsif (abs($surr_l - $index_b) > abs($surr_r - $index_b)) {
          $surr_i = $surr_r;
        }
        else {
          $surr_i = $surr_l;
        };
      }

      # Only left surrounding is POS
      elsif ($surr_l && $surr_l_query->[TYPE]) {
        $surr_i = $surr_l;
      }

      # Only right surrounding is POS
      else {
        $surr_i = $surr_r;
      };

      # Join with surrounding operand
      if ($surr_i < $index_a) {

        # Precede the queries directly
        $new_query = _precedes_directly(
          $queries->[$surr_i]->[QUERY],
          $queries->[$index_a]->[QUERY]
        );

        # Set new query
        $queries->[$index_a] = [POS, $new_query->max_freq, $new_query];

        # Remove old query
        splice(@$queries, $surr_i, 1);

        CORE::next;
      };
    };

    if ($break-- < 0) {
      print_log('kq_sequtil', 'EMERGENCY BREAK') if DEBUG;
      return;
    };
  };

  # ####################################
  # Algorithm for operand combination: #
  ######################################
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

  return $queries[0]->[QUERY];
};


# Combine anchors that are directly next to each other
sub _combine_pos {
  my ($queries, $index_a, $index_b) = @_;

  # Join both operands
  my $query_a = $queries->[$index_a];
  my $query_b = $queries->[$index_b];
  my $new_query;

  # Create a follows directly,
  # because the second operand is buffered and should occur less often
  if ($index_a < $index_b) {
    $new_query = _succeeds_directly($query_b->[QUERY], $query_a->[QUERY]);
  }

  # Create a precedes directly
  else {
    $new_query = _precedes_directly($query_b->[QUERY], $query_a->[QUERY]);
  }

  # Set new query
  $queries->[$index_a] = [POS, $new_query->max_freq, $new_query];

  # Remove old query
  splice(@$queries, $index_b, 1);

  if (DEBUG) {
    print_log(
      'kq_sequtil',
      'Queries are consecutive, build query ' . $new_query->to_string
    );
  };
};


# Combine operands with anywhere inbetween
sub _combine_anywhere {
  my ($queries, $index_a, $index_b, $index_between) = @_;

  if (DEBUG) {
    print_log('kq_sequtil', "Combine to ANY distance with positions " .
                "$index_a:$index_between:$index_b");
  };

  my $new_query;
  my $anywhere = $queries->[$index_between]->[KQUERY];
  my $constraint = {};

  if ($anywhere->is_optional) {
    $constraint->{optional} = 1;
  };

  # Type is classed
  # This requires, that the operand is normalized so classes always nest
  # repetitions and not the other way around
  while ($anywhere->type eq 'class') {
    $constraint->{classes} //= [];
    push @{$constraint->{classes}}, $anywhere->number;

    print_log('kq_sequtil', "Unpack classed query " . $anywhere->to_string) if DEBUG;

    # Return inner-query
    $anywhere = $anywhere->operand;
  };

  # Type is repetition
  if ($anywhere->type eq 'repetition') {
    $constraint->{min} = $anywhere->min;
    $constraint->{max} = $anywhere->max;
    $anywhere = $anywhere->operand;
  }

  else {
    $constraint->{min} = 1;
    $constraint->{max} = 1;
  };

  # Anywhere now should be a simple term
  if ($anywhere->type ne 'token') {
    die 'Any token is not term but ' . $anywhere->type;
  };

  # Respect sorting order
  if ($index_a < $index_b) {
    $constraint->{direction} = 'succeeds';
  }
  else {
    $constraint->{direction} = 'precedes';
  };

  # Return constraint with query a being rare
  $new_query = _constraint(
    $queries->[$index_b]->[QUERY],
    $queries->[$index_a]->[QUERY],
    $constraint
  );

  # Set new query
  $queries->[$index_a < $index_b ? $index_a : $index_b] =
    [POS, $new_query->max_freq, $new_query];

  # Remove old query
  splice(@$queries, $index_between, 2);

  if (DEBUG) {
    print_log(
      'kq_sequtil',
      'Queries are in a distance, build query ' . $new_query->to_string
    );
  };
};


# Combine operands with not between
sub _combine_neg {
  my ($queries, $index_a, $index_b, $index_between, $index) = @_;

  my $new_query;
  my $constraint = {};

  my $query = $queries->[$index_between]->[KQUERY];

  # TODO:
  #   Better use the builder and normalize - this will do all
  #   the optimizations on the fly (including min_span/max_span optimization)

  # Negative element is optional
  if ($query->is_optional) {
    $constraint->{optional} = 1;
    $constraint->{min} = 0;

    # Resolve optionality
    if ($query->type eq 'repetition') {

      # Finalize query, so optionality may be removed
      $query = $query->finalize;
    };

    # TODO:
    #   $constraint->{max} = $neg->max_length
  };

  # Type is classed
  while ($query->type eq 'class') {
    $constraint->{classes} //= [];
    push @{$constraint->{classes}}, $query->number;

    # Return inner-query
    $query = $query->operand;
  };

  my $neg = $query->optimize($index);

  # Negative operand can't occur - rewrite to anywhere query, but
  # keep quantities intact (i.e. <!s> can have different length than [!a])
  if ($neg->max_freq == 0) {
    if (DEBUG) {
      print_log('kq_sequtil', 'Negative query ' . $query->to_string . ' never occurs');
    };

    # Treat non-existing negative operand as an ANY query
    # TODO:
    #   This doesn't work now properly
    _combine_anywhere($queries, $index_a, $index_b, $index_between);
    return;
  };

  # Respect sorting order
  if ($index_a < $index_b) {
    $constraint->{direction} = 'succeeds';
  }
  else {
    $constraint->{direction} = 'precedes';
  };

  # Set negative query
  $constraint->{neg} = $neg;

  # Return constraint with query a being rare
  $new_query = _constraint(
    $queries->[$index_b]->[QUERY],
    $queries->[$index_a]->[QUERY],
    $constraint
  );

  # Set new query
  $queries->[$index_a < $index_b ? $index_a : $index_b] =
    [POS, $new_query->max_freq, $new_query];

  # Remove old query
  splice(@$queries, $index_between, 2);

  if (DEBUG) {
    print_log(
      'kq_sequtil',
      'Queries are in a negative distance, build query ' . $new_query->to_string
    );
  };
};


# Combine to optional sequence
sub _combine_opt {
  my ($queries, $index_a, $index_b, $index_between, $index) = @_;

  warn 'This is deprecated';

  my $new_query;
  my $opt = $queries->[$index_between]->[KQUERY];

  # Optimize
  $opt = $opt->finalize->optimize($index);
  $queries->[$index_between]->[QUERY] = $opt;
  $queries->[$index_between]->[FREQ] = $opt->max_freq;

  my $constraint = {};

  my $query_a = $queries->[$index_a];
  my $query_between = $queries->[$index_between];
  my $query_b = $queries->[$index_b];

  # One element matches nowhere - the whole sequence matches nowhere
  if ($opt->max_freq == 0) {

    if (DEBUG) {
      print_log(
        'kq_sequtil',
        'Optional operand does not occur - ignore ' . $opt->to_string
      );
    };

    # Create a follows directly,
    # because the second operand is buffered and should occur less often
    if ($index_a < $index_b) {
      $new_query = _succeeds_directly($query_b->[QUERY], $query_a->[QUERY]);
    }

    # Create a precedes directly
    else {
      $new_query = _precedes_directly($query_b->[QUERY], $query_a->[QUERY]);
    }

    # Set new query
    $queries->[$index_a] = [POS, $new_query->max_freq, $new_query];

    # Remove old query
    splice(@$queries, $index_between, 2);
  }

  # The optional operand exists
  else {

    my $alt_query;

    # a precedes b, so between precedes b
    if ($index_a < $index_between) {

      # Query b is less frequent - order
      if ($query_b->[FREQ] < $query_between->[FREQ]) {
        $alt_query = _precedes_directly($query_between->[QUERY], $query_b->[QUERY]);
      }
      else {
        $alt_query = _succeeds_directly($query_b->[QUERY], $query_between->[QUERY]);
      };
    }

    else {

      # Query b is less frequent - order
      if ($query_b->[FREQ] < $query_between->[FREQ]) {
        $alt_query = _succeeds_directly($query_between->[QUERY], $query_b->[QUERY]);
      }
      else {
        $alt_query = _precedes_directly($query_b->[QUERY], $query_between->[QUERY]);
      };
    };

    # Make query optional
    $alt_query = _or($query_b->[QUERY], $alt_query);

    if (DEBUG) {
      print_log(
        'kq_sequtil',
        'Create optional query element ' . $alt_query->to_string
      );
    };


    # Make [a][b]?[c] -> [a]([c]|[b][c])
    if ($index_a < $index_b) {
      $new_query = _succeeds_directly($alt_query, $query_a->[QUERY]);
    }

    # Create a precedes directly
    else {
      $new_query = _precedes_directly($alt_query, $query_a->[QUERY]);
    }

    # Set new query
    $queries->[$index_a < $index_b ? $index_a : $index_b] =
      [POS, $new_query->max_freq, $new_query];

    # Remove old query
    splice(@$queries, $index_between, 2);
  };

  if (DEBUG) {
    print_log(
      'kq_sequtil',
      'Queries are in an optional distance, build query ' . $new_query->to_string
    );
  };
};


# Extend to optional sequence
sub _extend_opt {
  my ($queries, $index_a, $index_b, $index) = @_;

  print_log('kq_sequtil', 'Extend operand with optional operand') if DEBUG;

  # TODO:
  #   This is kind of redundant
  my $surr_l = $index_a - 1;
  my $surr_r = $index_a + 1;
  my $surr_l_query = $surr_l >= 0 ? $queries->[$surr_l] : undef;
  my $surr_r_query = $surr_r < scalar(@$queries) ? $queries->[$surr_r] : undef;
  my $index_ext;

  # The left surrounding index is optional
  if ($surr_l_query && $surr_l_query->[TYPE] == OPT) {

    print_log('kq_sequtil', 'Left optional operand exists') if DEBUG;

    # Choose the left surrounding
    $index_ext = $surr_l;

    # Choose the one with the least frequency
    # Optimize both surroundings
    unless ($surr_l_query->[QUERY]) {
      $surr_l_query->[QUERY] = $surr_l_query->[KQUERY]->finalize->optimize($index);
      $surr_l_query->[FREQ] = $surr_l_query->[QUERY]->max_freq;
      if (DEBUG) {
        print_log('kq_sequtil', 'Optimize query ' . $surr_l_query->[KQUERY]->to_string);
      };
    };

    # Both surroundings are optional
    if ($surr_r_query && $surr_r_query->[TYPE] == OPT) {

      unless ($surr_r_query->[QUERY]) {
        $surr_r_query->[QUERY] = $surr_r_query->[KQUERY]->finalize->optimize($index);
        $surr_r_query->[FREQ] = $surr_r_query->[QUERY]->max_freq;
        if (DEBUG) {
          print_log('kq_sequtil', 'Optimize query ' . $surr_r_query->[KQUERY]->to_string);
        };
      };

      # Left surrounding has the lower frequency
      if ($surr_l_query->[FREQ] < $surr_r_query->[FREQ]) {
        $index_ext = $surr_l;
      }

      # Right surrounding has the lower frequency
      elsif ($surr_l_query->[FREQ] > $surr_r_query->[FREQ]) {
        $index_ext = $surr_r;
      }

      # Both have the same frequency
      # Choose the surrounding nearer to index_b
      # Or choose the option left
      elsif (abs($surr_l - $index_b) > abs($surr_r - $index_b)) {
        $index_ext = $surr_r;
      };
    }
  }

  # Only right surrounding is optional
  else {
    $index_ext = $surr_r;

    # Optimize right surrounding
    unless ($surr_r_query->[QUERY]) {
      $surr_r_query->[QUERY] = $surr_r_query->[KQUERY]->finalize->optimize($index);
      $surr_r_query->[FREQ] = $surr_r_query->[QUERY]->max_freq;
      if (DEBUG) {
        print_log('kq_sequtil', 'Optimize query ' . $surr_r_query->[KQUERY]->to_string);
      };
    };
  };

  my $query_a = $queries->[$index_a];
  my $query_ext = $queries->[$index_ext];

  if (DEBUG) {
    print_log(
      'kq_sequtil',
      'Extend ' . $query_a->[QUERY]->to_string . ' with ' . $query_ext->[QUERY]->to_string);
  };

  # Optional element does not exist
  if ($query_ext->[FREQ] == 0) {

    if (DEBUG) {
      print_log(
        'kq_sequtil',
        'Optional operand does not occur - ignore ' . $query_ext->[QUERY]->to_string
      );
    };

    # Remove old query
    splice(@$queries, $index_ext, 1);
    return 1;
  };

  # The optional operand exists - create new operand
  my $new_query;

  # Extension is to the right
  if ($index_a < $index_ext) {

    # Make the low frequency operand occur second
    if ($query_a->[FREQ] > $query_ext->[FREQ]) {
      $new_query = _precedes_directly($query_a->[QUERY], $query_ext->[QUERY]);
    }
    else {
      $new_query = _succeeds_directly($query_ext->[QUERY], $query_a->[QUERY]);
    };
  }

  # Extension is to the left
  else {

    # Make the low frequency operand occur second
    if ($query_a->[FREQ] > $query_ext->[FREQ]) {
      $new_query = _succeeds_directly($query_a->[QUERY], $query_ext->[QUERY]);
    }
    else {
      $new_query = _precedes_directly($query_ext->[QUERY], $query_a->[QUERY]);
    };
  };

  # Make query optional
  # $new_query = _or($query_a->[KQUERY]->optimize($index), $new_query);
  $new_query = _or($query_a->[QUERY]->clone, $new_query);

  # Add new query
  $queries->[$index_a] = [POS, $new_query->max_freq, $new_query];

  # Remove old query
  splice(@$queries, $index_ext, 1);

  if (DEBUG) {
    print_log(
      'kq_sequtil',
      'Query has an optional extension, build query ' . $new_query->to_string
    );
  };
};


# Extend to anymatch sequence
sub _extend_any {
  my ($queries, $index_a, $index_b, $index) = @_;

  print_log('kq_sequtil', 'Extend operand with any match operand') if DEBUG;

  # TODO:
  #   This is kind of redundant
  my $surr_l = $index_a - 1;
  my $surr_r = $index_a + 1;
  my $surr_l_query = $surr_l >= 0 ? $queries->[$surr_l] : undef;
  my $surr_r_query = $surr_r < scalar(@$queries) ? $queries->[$surr_r] : undef;
  my $index_ext;

  # The left surrounding index matches anywhere
  if ($surr_l_query && $surr_l_query->[TYPE] == ANY) {

    # Both surroundings match anywhere
    if ($surr_r_query && $surr_r_query->[TYPE] == ANY) {
      # TODO:
      #   Compare min_span and max_span, and prefer
      #   the smaller expansion over the larger one,
      #   although this desicion needs to be benchmarked,
      #   because choosing right extension may always
      #   be faster
      $index_ext = $surr_r;
    }

    # Only the left query is an any query
    else {
      $index_ext = $surr_l;
    }
  }

  # Only the right query is an any query
  else {
    $index_ext = $surr_r;
  };

  my $query_a = $queries->[$index_a];
  my $query_ext = $queries->[$index_ext];

  # The optional operand exists - create new operand
  my $new_query;

  my $ext = $query_ext->[KQUERY];
  my @ranges = ([$ext->min, $ext->max]);
  $ext = $ext->operand;

  # Collect all ranges
  while ($ext->type eq 'repetition') {
    unshift @ranges, [$ext->min, $ext->max];
    $ext = $ext->operand;
  };

  # Create new extension query
  $new_query = Krawfish::Query::Extension->new(
    # Extension is to the left or to the right
    $index_a < $index_ext ? 0 : 1,
    $query_a->[QUERY]->clone,
    \@ranges
  );

  # Add new query
  $queries->[$index_a] = [POS, $new_query->max_freq, $new_query];

  # Remove old query
  splice(@$queries, $index_ext, 1);

  if (DEBUG) {
    print_log(
      'kq_sequtil',
      'Query has an any extension, build query ' . $new_query->to_string
    );
  };
}


# Get the query segments based on frequency,
# if even, get the one that is closer to the middle
sub _get_best_pair {
  my $queries = shift;
  my @best = ();
  my $length = scalar @$queries;

  # Iterate over all operands
  for (my $i = 0; $i < $length; $i++) {

    # Operand is not pos
    CORE::next unless $queries->[$i]->[TYPE] == POS;

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

      CORE::next;
    };

    my $freq = $queries->[$i]->[FREQ];

    # Next query is not among the best
    CORE::next if $freq > $queries->[$best[1]]->[FREQ];

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



# Build methods
# Create raw queries

sub _precedes_directly {
  my ($query_a, $query_b) = @_;

  return Krawfish::Query::Constraint->new(
    [Krawfish::Query::Constraint::Position->new(PRECEDES_DIRECTLY)],
    $query_a,
    $query_b
  );
};


sub _succeeds_directly {
  my ($query_a, $query_b) = @_;

  return Krawfish::Query::Constraint->new(
    [Krawfish::Query::Constraint::Position->new(SUCCEEDS_DIRECTLY)],
    $query_a,
    $query_b
  );
};


sub _or {
  my ($query_a, $query_b) = @_;

  return Krawfish::Query::Or->new(
    $query_a,
    $query_b
  );
};


# TODO:
#   Does not support tokens and gaps yet
sub _constraint {
  my ($query_a, $query_b, $constraint) = @_;

  # Distance is optional
  my $pos_frame;

  if ($constraint->{direction} eq 'precedes') {
    $pos_frame = PRECEDES;
    $pos_frame |= PRECEDES_DIRECTLY if $constraint->{optional};
  }
  elsif ($constraint->{direction} eq 'succeeds') {
    $pos_frame = SUCCEEDS;
    $pos_frame |= SUCCEEDS_DIRECTLY if $constraint->{optional};
  }
  else {
    warn 'Unknown direction '. $constraint->{direction};
    return;
  };

  my @constraints = ();

  push @constraints,
    Krawfish::Query::Constraint::Position->new($pos_frame);

  # Add distance constraint
  if (defined $constraint->{min} || defined $constraint->{max}) {
    push @constraints,
      Krawfish::Query::Constraint::InBetween->new($constraint->{min}, $constraint->{max});
  };

  # There is a negative constraint
  if ($constraint->{neg}) {
    push @constraints,
      Krawfish::Query::Constraint::NotBetween->new($constraint->{neg});
  };

  # Add class constraint
  if ($constraint->{classes}) {
    foreach (@{$constraint->{classes}}) {
      push @constraints,
        Krawfish::Query::Constraint::ClassBetween->new($_);
    };
  };

  # Return constraint query
  return Krawfish::Query::Constraint->new(
    \@constraints,
    $query_a,
    $query_b
  );
};


1;


__END__
