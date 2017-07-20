package Krawfish::Koral::Util::Sequential;
use Krawfish::Log;
use Krawfish::Query::Nothing;
use Krawfish::Query::Constraint::Position;
use Krawfish::Query::Constraint::InBetween;
use Krawfish::Query::Constraints;
use List::MoreUtils qw!uniq!;
use strict;
use warnings;

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
  # $self = $self->_resolve_consecutive_repetitions;

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
# sub finalize;

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
#
sub optimize {
  my ($self, $index) = @_;

  print_log('kq_sequtil', 'Optimize sequence') if DEBUG;

  # Length of operand size with different types
  # Stores values as [TYPE, FREQ, QUERY, KQUERY]
  my @queries;

  # Remember the least common non-optional positive query
  my $filterable_query;

  # Classify all operands into the following groups:
  #   POS: positive operand (directly queriable)
  #   OPT: optional operand
  #   NEG: negative operand
  #   ANY: any query
  my $ops = $self->operands;
  for (my $i = 0; $i < $self->size; $i++) {

    my $op = $ops->[$i];

    # Query matches anywhere
    if ($op->is_any) {
      $queries[$i] = [ANY, -1, undef, $op];
    }

    # Is negative operand
    elsif ($op->is_negative) {

      $queries[$i] = [NEG, -1, undef, $op];
    }

    # Is positive operand
    else {

      # The operand is not optional, so the filter may be applied
      unless ($ops->[$i]->is_optional) {

        # Directly collect positive queries
        my $query = $ops->[$i]->optimize($index);

        # Get frequency of operand
        my $freq = $query->max_freq;

        if (DEBUG) {
          print_log('kq_sequtil', 'Get frequencies for possible anchor ' . $query->to_string);
        };

        # One element matches nowhere - the whole sequence matches nowhere
        return Krawfish::Query::Nothing->new if $freq == 0;

        # Current query is less common
        if (!defined $filterable_query || $freq < $queries[$filterable_query]->max_freq) {
          $filterable_query = $_;
        };
        $queries[$i] = [POS, $freq, $query, $ops->[$i]];
      }

      # The operand is optional
      else {
        print_log('kq_sequtil', $ops->[$i]->to_string . ' is optional') if DEBUG;
        $queries[$i] = [OPT, -1, undef, $ops->[$i]];
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
    my $dist = defined $index_b ? abs($index_a - $index_b) : 0;

    print_log('kq_sequtil', 'Distance is ' . $dist) if DEBUG;

    # Best operands are consecutive
    if ($dist == 1) {

      # Combinde positives
      _combine_pos($queries, $index_a, $index_b);

      # Go to next combination
      next;
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
        _combine_any($queries, $index_a, $index_b, $index_between);
        next;
      }

      # b) If there is an optional, variable, classed NEG operand
      #    in between, make a not_between query

      # The inbetween is NEGATIVE
      elsif ($queries->[$index_between]->[TYPE] == NEG) {
        _combine_neg($queries, $index_a, $index_b, $index_between, $index);
        next;
      };

      print_log('kq_sequtil', 'Can\'t combine ANY or NEG operands') if DEBUG;
    };

    # Matches are too far away or there is no index_b
    # Extend with surrounding operands
    print_log('kq_sequtil', 'Extend operand with surrounding') if DEBUG;

    # Get surrounding queries
    my $surr_l = $index_a - 1;
    my $surr_r = $index_a + 1;
    my $surr_i;
    my $surr_l_query = $surr_l > 0 ? $queries->[$surr_l] : undef;
    my $surr_r_query = $surr_r < scalar(@$queries) ? $queries->[$surr_r] : undef;
    my $new_query;

    # c) If there is an optional, variable, classed OPT operand
    #    make an extension
    if (($surr_l_query && $surr_l_query->[TYPE] == OPT) ||
          ($surr_r_query && $surr_r_query->[TYPE] == OPT)) {
      _extend_opt($queries, $index_a, $index_b, $index);
      next;
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

        next;
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


# Combine operands with any inbetween
sub _combine_any {
  my ($queries, $index_a, $index_b, $index_between) = @_;

  my $new_query;
  my $any = $queries->[$index_between]->[KQUERY];
  my $constraint = {};

  if ($any->is_optional) {
    $constraint->{optional} = 1;
  };

  # Type is classed
  if ($any->type eq 'class') {
    $constraint->{class} = $any->number;

    # Return inner-query
    $any = $any->span;
  };

  # Type is repetition
  if ($any->type eq 'repetition') {
    $constraint->{min} = $any->min;
    $constraint->{max} = $any->max;
  }

  else {
    $constraint->{min} = 1;
    $constraint->{max} = 1;
  };

  # Any now should be a simple term
  if ($any->type ne 'token') {
    die 'Any token is not term!';
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
  if ($query->type eq 'class') {
    $constraint->{class} = $query->number;

    # Return inner-query
    $query = $query->span;
  };

  my $neg = $query->optimize($index);

  # Negative operand can't occur - rewrite to any query, but
  # keep quantities intact (i.e. <!s> can have different length than [!a])
  if ($neg->max_freq == 0) {
    if (DEBUG) {
      print_log('kq_sequtil', 'Negative query ' . $query->to_string . ' never occurs');
    };

    # Treat non-existing negative operand as an ANY query
    # TODO:
    #   This doesn't work now properly
    _combine_any($queries, $index_a, $index_b, $index_between);
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

  my $surr_l = $index_a - 1;
  my $surr_r = $index_a + 1;
  my $surr_l_query = $surr_l > 0 ? $queries->[$surr_l] : undef;
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
  # TODO:
  #   Introduce a ->clone() method!
  $new_query = _or($query_a->[KQUERY]->optimize($index), $new_query);

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



# Build methods
# Create raw queries

sub _precedes_directly {
  my ($query_a, $query_b) = @_;

  return Krawfish::Query::Constraints->new(
    [Krawfish::Query::Constraint::Position->new(PRECEDES_DIRECTLY)],
    $query_a,
    $query_b
  );
};


sub _succeeds_directly {
  my ($query_a, $query_b) = @_;

  return Krawfish::Query::Constraints->new(
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
  if ($constraint->{class}) {
    push @constraints,
      Krawfish::Query::Constraint::ClassDistance->new($constraint->{class});
  };

  # Return constraint query
  return Krawfish::Query::Constraints->new(
    \@constraints,
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
          if ($query->max_freq <= $queries[$next_i]->max_freq) {

            print_log(
              'kq_sequtil',
              'Freq is '. $query->to_string . ' <= ' .$queries[$next_i]->to_string
            ) if DEBUG;

            $query = _precedes_directly($query, $queries[$next_i]);
          }

          # Reverse the order due to frequency optimization
          else {
            $query = _succeeds_directly($queries[$next_i], $query);
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
