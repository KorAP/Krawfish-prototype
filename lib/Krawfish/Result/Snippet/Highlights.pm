package Krawfish::Result::Snippet::Highlights;
use Krawfish::Log;
use strict;
use warnings;

use constant DEBUG => 1;

# -1 is match highlight
# $annotation_nr_counter = 256;
# $relation_number_counter = 2048;
# $identifier_number_counter = -2;

# private HashMap<Integer, String> annotationNumber = new HashMap<>(16);
# private HashMap<Integer, Relation> relationNumber = new HashMap<>(16);
# private HashMap<Integer, Integer> identifierNumber = new HashMap<>(16);

sub new {
  my $class = shift;
  bless {
    highlights => shift,
    segments   => shift,
    list       => [], # Combined array
    stack      => [] # Stack for balancing the elements
  }, $class;
};


sub clear {
  ...
};


sub add_open {
  my $self = shift;
};

sub process {
  ...
};

1;

__END__


sub parse_simple {
  my $self = shift;

  my $segments = $self->{segments};

  # TODO:
  #   In Krill, offsets are collected in advance,
  #   but I guess it's cleaner to do on the fly

  print_log('c_highl', 'Process highlight stack') if DEBUG;

  my @highlights = ();

  # my $start_seg = $segments->get($match->doc_id, $match->start);
  # my $end_seg   = $segments->get($match->doc_id, $match->end - 1);

  # Add match as highlight
  push @highlights, _highlight($match->start, $match->end, -1);

  # TODO:
  #   Check that highlights are between these values
  # my $start_pos = $match->start;
  # my $end_pos = $match->end;

  # TODO:
  #   Filter multiple identifiers, that may be introduced and would
  #   result in invalid xml
  # this._filterMultipleIdentifiers();

  my @open_list  = sort _open_sort @highlights;
  my @close_list = sort _close_sort @highlights;

  # Final highlight stack
  my @stack = ();

  # Create sorted stack unless both lists are empty
  while (scalar @open_list || scalar @close_list) {

    # Shortcut for list ending
    if (!scalar @open_list) {
      push @stack, map { $_->[4] = } @close_list;
      last;
    }

    # Not sure about this - but may happen
    elsif (!scalar @close_list) {
      last;
    };

    # Type 0: Textual data
    # Type 1: Opening
    # Type 2: Closing

    # Check if the opening tag starts before the closing tag ends
    if ($open_list[0]->[0] < $close_list[0]->[1]) {

      # Clone highlight
      my $element = [@{(shift(@open_list))}];

      # Set element to be terminal
      $element->[3] = 1; # terminal
      $element->[4] = 1; # Opening
      push @stack, $element;
    }

    # No - then close
    else {
      my $element = shift(@close_list);
      $element->[4] = 2; # closing
      push @stack, $element;
    };
  };

  $self->{stack} = \@stack; # is a position stack!

  # TODO:
  #   Problem to solve is now discontinuing elements!

  return $self;
};


sub _highlight {
  my ($start, $end, $class, $terminal) = @_;
  return [$start, $end, $class, $terminal // 0];
};

# Sort opening tags by start, end and class number
sub _open_sort {

  # Compare start position
  if ($a->start > $b->start) {
    return 1;
  }
  elsif ($a->start == $b->start) {
    # Compare end position
    if ($a->end > $b->end) {
      return -1;
    }
    elsif ($a->end == $b->end) {
      # Compare class number
      if ($a->[2] > $b->[2]) {
        return 1;
      }
      elsif ($a->[2] < $b->[2]) {
        return -1;
      };
      return 0;
    };
  }
  return -1;
};


# Sort closing tags by end and start
sub _close_sort {

  # Compare end positions
  if ($a->[1] > $b->[1]) {
    return 1;
  }
  elsif ($a->[1] == $b->[1]) {

    # Compare start position
    if ($a->[0] < $b->[0]) {
      return 1;
    }
    elsif ($a->[0] == $b->[0]) {
      return 0;
    };
    return -1;
  };
  return -1;
};





1;




__END__

sub parse {
  my ($self, $match) = @_;

  my $segments = $self->{segments};

  # Collect offsets for match
  # TODO: In Krill, offsets are collected in advance,
  # but I guess it's cleaner to do on the fly
  my $start_seg = $segments->get($match->doc_id, $match->start);
  my $end_seg   = $segments->get($match->doc_id, $match->end - 1);

  # TODO: Collect offsets for inner match

  # match number

  # TODO: Parse identifier string

  # $self->add_open(0, $start_seg->[0]);
  # $self->add_close(0, $end_seg->[1]);

  # foreach (@highlights) {
  #   if ($_->start >= $match->start && $_->end <= $self->end) {
  #
  #   };
  # }

  my $stack = $self->_process_highlight_stack;
  return $self->{list};
};


sub _process_highlight_spans {
  my $self = shift;

  # TODO:
  #   Check potential start and end characters here

  my $identifier = undef;

  # my $array = $self->_process_offset_chars($match->doc_id);

  # foreach my $highlight (@{$self->highlights}) {
  #   my $start = $self->{segments}->get($match->doc_id, $highlight->start);
  #   my $end = $self->{segments}->get($match->doc_id, $highlight->end);

  #  return if $start < 0 || $end < 0;
  #  $self->{span}->add($start, $end, $highlight->nr);
  # };
};


# TODO: Process context, primary data
sub _process_offset_chars {
#  my $self = shift;
  #  if ($context) {}
};

sub _process_highlight_stack {
  my $self = shift;

  print_log('c_highl', 'Process highlight stack') if DEBUG;

  my @open_list = ();
  my @close_list = ();

  # TODO:
  #   Filter multiple identifiers, that may be introduced and would
  #   result in invalid xml
  # this._filterMultipleIdentifiers();

  my @highlights = @_;

  push @open_list,  @highlights;
  push @close_list, @highlights;

  @open_list  = sort _open_sort  @open_list;
  @close_list = sort _close_sort @open_list;

  my @stack = ();

  # Create sorted stack unless both lists are empty
  while (scalar @open_list || scalar @close_list) {
    if (!scalar @open_list) {
      push @stack, @close_list;
      last;
    }

    # Not sure about this - but may happen
    elsif (!scalar @close_list) {
      last;
    };

    if ($open_list[0]->start < $close_list[0]->end) {

      my $e = (shift(@open_list))->clone;
      $e->[3] = 1;
      push @stack, $e;
    }
    else {
      push @stack, shift(@close_list)
    };
  };
  return \@stack;
};

sub add_close {
  my $self = shift;
  my ($nr, $end) = @_;

  $self->{temp_stack} = [];

  # Check if there is an opening tag
  unless ($self->{stack}->[0]) {
    warn 'Nothing to close on stack';
    return;
  };

  if (DEBUG) {
    print_log(
      'c_highl',
      "Stack for checkinmg with class $nr is " .
        join('|', @{$self->{stack}})
      );
  };


  # Class number of the last element
  my $eold  = pop @{$self->{stack}};

  my $last_combinator;

  # the closing element is not balanced, i.e. the last element differs
  while ($eold != $nr) {

    # Get last element
    $last_combinator = $self->{list}->[-1];

    if (DEBUG) {
      print_log(
        'c_highl',
        'Closing element is unbalanced - ' .
          $eold . ' != ' . $nr . ' with last combinator ' .
          join('|',
               $last_combinator->{type},
               $last_combinator->{nr},
               $last_combinator->{chars}
             )
        );
    };

    # combinator is opening and the number is not equal to the last
    # element on the balanceStack
    if ($last_combinator->{type} == 1 && $last_combinator->{nr} == $eold) {

      # Remove the last element - it's empty and uninteresting!
      pop @{$self->{list}};
    }

    # combinator is either closing (??) or another opener
    else {

      print_log('c_highl', "Close element a) $eold") if DEBUG;

      # Add close element of the unclosed element
      # This will be continued
      push @{$self->{list}}, Krawfish::Collection::Snippet::Highlights::Combinator->new_node(
        2, $eold, 0
      );
    };

    # add this element number temporarily on the stack
    push @{$self->{temp_stack}}, $eold;

    # Check next element
    $eold = pop @{$self->{stack}};
  };

  # Get last combinator on the stack
  $last_combinator = $self->{list}->[-1];

  if (DEBUG) {
    print_log(
      'c_highl',
      "LastComb: " .
        join('|',
             $last_combinator->{type},
             $last_combinator->{nr},
             $last_combinator->{chars}
           ) .
           " for $nr"
         );
  };

  if ($last_combinator->{type} == 1 && $last_combinator->{nr} == $nr) {

    while ($last_combinator->{type} == 1 && $last_combinator->{nr} == $nr) {
      # Remove the damn thing - It's empty and uninteresting!
      pop @{$self->{list}};
      $last_combinator = $self->{list}->[-1];
    };
  }

  else {
    print_log('c_highl', "Close element b) $nr") if DEBUG;

    # Add closer
    push @{$self->{list}}, Krawfish::Collection::Snippet::Highlights::Combinator->new_node(
      2, $eold, 1
    );
  };

  for my $e (@{$self->{temp_stack}}) {
    print_log('c_highl', "Reopen element $e") if DEBUG;
    push @{$self->{list}}, Krawfish::Collection::Snippet::Highlights::Combinator->new_node(
      1, $e
    );

    push @{$self->{stack}}, $e;
  };
};


sub get_first {
  $_[0]->{list}->[0];
};


sub get_last {
  $_[0]->{list}->[-1];
};


sub get {
  $_[0]->{list}->[$_[1]];
};


sub size {
  scalar @{$_[0]->{list}}
};


# Add textual element
sub add_string {
  my ($self, $string) = @_;
  my $element = Krawfish::Collection::Snippet::Highlights::Combinator->new_text(
    $string
  );
  push @{$self->{list}}, $element;
};


# Open element
sub add_open {
  my ($self, $number) = @_;

  my $element = Krawfish::Collection::Snippet::Highlights::Combinator->new_node(
    1 => $number
  );
  push @{$self->{list}}, $element;
  push @{$self->{stack}}, $number;
};


sub to_string {
  my $self = shift;
  my $str = '';
  foreach (@{$self->{list}}) {
    $str .= $_->to_string . "\n";
  };
  return $str;
};


package Krawfish::Collection::Snippet::Highlights::Combinator;
use strict;
use warnings;

# Type 0: Textual data
# Type 1: Opening
# Type 2: Closing

# Constructor for nodes
sub new_node {
  my $class = shift;
  my $self = bless {
    type => shift,         # byte
    nr => shift,           # integer
    terminal => shift // 1, # boolean
    chars => ''
  }, $class;

  # Terminal elements are closed and won't be reopened

  return $self;
};


# Constructor for textual data
sub new_text {
  my $class = shift;
  bless {
    type => 0,
    chars => shift,
    nr => 0,
    terminal => 1
  }, $class;
};


# TODO: This may not be set here
sub to_bracket {
  my $self = shift;
  my $match = shift;

  my $str = '';

  # Closing bracket
  if ($self->{type} == 2) {

    # Close matching element
    if ($self->{nr} == -1) {
      return ']';
    };

    # Close matching highlight, relation, span ...
    return '}';
  }

  elsif ($self->{type} == 1) {
    if ($self->{nr} == -1) {
      $str .= '[';
    }

    # Is identifier
    elsif ($self->{nr} < -1) {
      $str .= '{#' . $match->class_id($self->{nr}) . ':';
    }

    # Highlight, relation, Span
    else {
      $str .= '{';

      # Todo: Use highlight directive

      if ($self->{nr} >= 256) {

        # Is an annotation?
        if ($self->{nr} < 2048) {
          $str .= $match->annotation_id($self->{nr});
        }

        # Relation
        else {
          my $rel = $match->relation_id($self->{nr});
          $str .= $rel->annotation;
          $str .= '>';
        }
      }

      # Highlight
      elsif ($self->{nr} != 0) {
        $str .= $self->{nr} . ':';
      }

      return $str;
    };

    return $self->{chars};
  };
};

1;
