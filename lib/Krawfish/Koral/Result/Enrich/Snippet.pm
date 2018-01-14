package Krawfish::Koral::Result::Enrich::Snippet;
use strict;
use warnings;
use Krawfish::Util::Constants qw/:PREFIX MAX_CLASS_NR/;
use Krawfish::Log;
use Krawfish::Koral::Result::Enrich::Snippet::Primary;
use Role::Tiny::With;

with 'Krawfish::Koral::Result::Inflatable';

# The structure of a match is as follows:
#
# <context>
#   <more />
#   ...             # Pure text and decorations
#   <focus>         # Possible extension to elements
#     ...           # Pure text, decorations and annotations
#     <hit>         # The concrete hit
#       ...         # Pure text, decorations, annotations and highlights
#     </hit>
#     ...           # Pure text, decorations and annotations
#   </focus>
#   ...             # Pure text and decorations
#   <more />
# </context>


# TODO:
#   Make sure this works for right-to-left (RTL) language scripts as well!

# TODO:
#   Instead of dealing with characters and


use constant DEBUG => 1;

# Constructor
sub new {
  my $class = shift;

  # stream
  # stream_offset
  # doc_id

  # match_ids
  my $self = bless {
    @_
  }, $class;


  $self->{annotations} //= [];
  $self->{char_string} = undef;
  $self->{char_pos} = undef;
  return $self;
};


# Key for KQ serialization
sub key {
  'snippet'
};


# Inflate term ids to terms
sub inflate {
  my ($self, $dict) = @_;

  # Inflate the stream
  $self->stream($self->stream->inflate($dict));

  return $self;
};


# Set doc id
sub doc_id {
  my $self = shift;
  if (@_) {
    $self->{doc_id} = shift;
    return $self;
  };
  return $self->{doc_id};
};


# This stores a Krawfish::Koral::Document::Stream
# with the stream_offset subtoken at 0
sub stream {
  my $self = shift;
  if (@_) {
    $self->{stream} = shift;
    return $self;
  };
  return $self->{stream};
};


# Get the offset for stream positions
sub stream_offset {
  my $self = shift;
  if (@_) {
    $self->{stream_offset} = shift;
    return $self;
  };
  return $self->{stream_offset} // 0;
};


# Stringification
sub to_string {
  my ($self, $id) = @_;

  if ($id) {
    return $self->key . ':' . $self->stream->to_string($id);
  };

  if (DEBUG) {
    print_log('kq_snippet', 'Create ordered markup');
  };

  # Get list of annotations
  my $list = $self->_inline_markup(
    $self->_order_markup
  );

  return $self->key . ':' . join('', map { $_->to_brackets } @$list);
};


# Serialization
sub to_html {
  my ($self, $id) = @_;

    if (DEBUG) {
    print_log('kq_snippet', 'Create ordered markup');
  };

  # Get list of annotations
  my $list = $self->_inline_markup(
    $self->_order_markup
  );

  # Cache, that maps a highlight class to a level number
  my $level_cache = [];

  # Define a vector with set bits for all used levels
  # Can be used like a bitset
  my $level_vector = [(1) x MAX_CLASS_NR];

  my $str = '';
  foreach my $anno (@$list) {

    # Set level to annotation, if it is a highlight
    if ($anno->type eq 'highlight') {

      # Highlight is opening
      if ($anno->is_opening) {

        if (DEBUG) {
          my $level = _get_level($level_cache, $level_vector, $anno->number);

          $anno->level($level);

          if (DEBUG) {
            print_log(
              'kq_snippet',
              'Open highlight: ' . $anno->to_string . ' at l=' . $level
            );
            print_log(
              'kq_snippet',
              'Level vector is ' . join(',', @$level_vector)
            );
          };
        };
      }

      # Is closing and terminal
      elsif ($anno->is_terminal) {

        if (DEBUG) {
          print_log('kq_snippet', 'Close terminal highlight: ' . $anno->to_string);
        };

        # Level cache is defined for this class number
        if (defined $level_cache->[$anno->number]) {

          # If the annotation is terminal, remove the level from the vector
          $level_vector->[$level_cache->[$anno->number]] = 1;
          $level_cache->[$anno->number] = undef;
        };
      };
    };
    $str .= $anno->to_html;
  };

  return $str;
};


# Serialize KQ
sub to_koral_fragment {
  my $self = shift;
  '';
};


# Get the character positions of a token
sub start_char_pos {
  my ($self, $token_pos) = @_;

  # Not yet generated;
  unless ($self->{char_pos}) {
    $self->_create_primary_string;
  };

  # Return character position
  my $pos = $self->{char_pos}->[$token_pos];
  return $pos->[0] // 0;
};


# Get the character positions of a token
sub end_char_pos {
  my ($self, $token_pos) = @_;

  # Not yet generated;
  unless ($self->{char_pos}) {
    $self->_create_primary_string;
  };

  # Return character position
  my $pos = $self->{char_pos}->[$token_pos];

  # Return either the found position or the position
  # of the last token
  return $pos->[1] // $self->{char_pos}->[-1]->[1]
};


# Get character string
sub char_substr {
  my ($self, $start, $length) = @_;

  # Not yet generated;
  unless ($self->{char_string}) {
    $self->_create_primary_string;
  };

  return substr($self->{char_string}, $start, $length) if $length;
  return substr($self->{char_string}, $start);
};


# Fetch all primary data strings and
# create a single primary string with position matching
sub _create_primary_string {
  my $self = shift;

  if (DEBUG) {
    print_log('kq_snippet', 'Create primary string and token positions');
  };

  # Calculate character positions
  my $stream = $self->stream;

  my $i = $self->stream_offset;
  my $length = $stream->length + $self->stream_offset;

  my $char_string = '';

  my $current_pos = 0;
  my @char_position = ();

  # Iterate through the stream
  while ($i < $length) {

    # Get current primary data
    my ($preceding, $subterm) = $self->_subtoken($i);

    $subterm = substr($subterm, 1) if $subterm;

    # Add preceding characters
    $char_string .= $preceding;

    # Remember character offset
    $current_pos += length($preceding);

    # Add subterm characters
    $char_string .= $subterm;

    # Remember character position for token position
    $char_position[$i] = [
      $current_pos,
      $current_pos + length($subterm)
    ];

    # Remember character offset
    $current_pos += length($subterm) if $subterm;

    $i++;
  };

  # Prepend following preceding data, as it may be relevant
  my ($preceding) = $self->_subtoken($i);

  $self->{char_string} .= $preceding if $preceding;

  if (DEBUG) {
    print_log(
      'kq_snippet',
      'Primary data is ' . $char_string
    );
  };

  $self->{char_pos} = \@char_position;
  $self->{char_string} = $char_string;
};


# Add start_abs_char and end_abs_char
sub _add_real_char_positions {
  my $self = shift;

  # Initialize positions
  $self->_create_primary_string;

  # Iterate over all annotations
  foreach my $anno (@{$self->{annotations}}) {

    # Set abs_char
    $anno->start_abs_char(
      $self->char_pos($self->start)->[0] + $self->start_char
    );

    # Set abs_char
    $anno->end_abs_char(
      $self->char_pos($self->end)->[1] + $self->end_char
    );
  };
};


# Order all annotations based on their starting/ending positions
# This is based on processHighlightStack() in Krill
sub _order_markup {
  my $self = shift;
  my $stream = $self->stream;

  # TODO:
  #   Do not clone all elements but create index lists on the annotation
  #   lists and mark open/close in the stack structure, that will basically be
  #   [[index,openbool],[index,oprenbool],...]

  # 1. Take all markup and split into opening and closing tags
  #    - Milestones are only added as starts

  # 2. Sort the opening tags
  my @open = grep {

    # Do not open elements, that should start after all
    !$_->start_after_all

  } sort {

    # Sort for opening tags
    $a->compare_open($b)
  } @{$self->{annotations}};

  # 3. Sort the closing tags
  my @close = grep {

    # Do not close elements, that should end before next
    !$_->end_before_next
  } sort {

    # Sort for opening tags
    $a->compare_close($b)
  } @{$self->{annotations}};

  # 4. Create a stack or a list of the doubled length of
  #    the opening list
  my @stack = ();
  while (@open || @close) {

    if (DEBUG) {
      print_log('kq_snippet', 'Open or close list is not empty');
    };

    # No more open tags
    if (!@open) {

      if (DEBUG) {
        print_log(
          'kq_snippet',
          'Open is empty - push closener to stack: ' . $close[0]->to_string
        );
      };

      push @stack, shift @close;
      next;
    }

    # No more end tags
    elsif (!@close) {

      if (DEBUG) {
        print_log('kq_snippet', 'Close is empty - do nothing');
      };

      last;
    };

    if (DEBUG) {
      print_log('kq_snippet', 'Compare both tags');
    };

    # The first opener starts before the first closer ends
    if ($open[0]->start < $close[0]->end) {

      my $opener = shift(@open)->clone->is_opening(1);

      if (DEBUG) {
        print_log('kq_snippet', 'Push opener to stack: ' . $opener->to_string);
      };

      push @stack, $opener;
    }

    # First let the closer end
    else {
      if (DEBUG) {
        print_log('kq_snippet', 'Push closener to stack: ' . $close[0]->to_string);
      };

      push @stack, shift @close;
    };
  };

  if (DEBUG) {
    print_log(
      'kq_snippet',
      'Stack is <' . join('; ', map { $_->to_string } @stack) . '>'
    );
  };

  return \@stack;
};


# Iterate over all annotations and join with the primary data stream
# Based on HighlightCombinator.java in Krill
sub _inline_markup {
  my ($self, $stack) = @_;

  # 5. Iterate over the stream and add all annotations.
  #    Stream is:
  #    Krawfish::Koral::Document::Stream
  #    with surface annotations only
  my @list;
  my $stream = $self->stream;
  my $length = $stream->length + $self->stream_offset;
  my $i = $self->stream_offset;

  if (DEBUG) {
    print_log('kq_snippet', '> Inline markup elements at ' . $self->stream_offset);
  };

  my $anno = shift @$stack;

  # This is the balance stack for annotations!
  my @balance;

  # This is an intermediate stack for closing and reopening tags
  my @temp_balance;

  # Only take care of preceding data after start
  my $init = 0;

  # Get current annotation
  my ($preceding, $subterm) = $self->_subtoken($i);

  # TODO:
  #   Take care of preceding data for initial annotations with start_char
  #    and preceding data of following subtoken for ending annotations
  #    with end_char

  # TODO:
  #   Check for the case where the last subtoken is retrieved
  #   and the preceding data of the virtual last subtoken is needed
  while ($i < $length || $anno) {

    # No more annotations
    unless ($anno) {
      if (DEBUG) {
        print_log('kq_snippet', '1. Add text to list: ' . ($subterm ? $subterm : '-'));
      };
      push @list, _new_data($preceding) if $init++ && $preceding;
      push @list, _new_data(substr($subterm, 1)) if $subterm;
      ($preceding, $subterm) = $self->_subtoken(++$i);
    }

    # Next tag is opening
    elsif ($anno->is_opening) {

      # Add annotation start tag
      if ($anno->start == $i) {

        if (DEBUG) {
          print_log('kq_snippet', 'Annotation starts with subtoken' .
                      ' - add annotation to list ' . $anno->to_string . ' (1)');
        };

        # Take preceding data and ignore further
        if ($preceding) {

          # The start character
          if ($anno->start_char < 0) {
            my $start_char = $anno->start_char;

            if ($start_char < (-1 * length($preceding))) {
              warn 'invalid start char';
            };

            # Left preceding
            my $take = substr($preceding, 0, length($preceding) + $start_char);
            my $leave  = substr($preceding, $start_char);

            if (DEBUG) {
              print_log(
                'kq_snippet',
                'Annotation has start char at ' . $start_char,
                'From "' . $preceding . '" take "' . $take . '" and leave "'.$leave.'"'
              );
            };

            # Only add the first part, if given
            push @list, _new_data($take) if $init++ && $take;
            $preceding = $leave;
          }
          else {
            push @list, _new_data($preceding) if $init++;
            $preceding = undef;
          };
        };


        # Check, if the last annotation on the balance stack is opening and has a
        # close-immediately marker (e.g. on left contexts)
        while ($balance[0] && $balance[0]->is_opening && $balance[0]->end_before_next) {

          if (DEBUG) {
            print_log('kq_snippet', 'Last element on stack is end-before-next');
          };

          my $close = shift(@balance)->clone->is_opening(0);

          if (DEBUG) {
            print_log('kq_snippet', 'Add annotation to list ' . $close->to_string . ' (1 1/2)');
          };

          push @list, $close;
        };

        if (DEBUG) {
          print_log('kq_snippet', 'Add annotation to list ' . $anno->to_string . ' (2)');
        };

        push @list, $anno;
        unshift @balance, $anno;
        $anno = shift @$stack;

        if (DEBUG) {
          print_log(
            'kq_snippet',
            'Balance-Stack is <' . join('; ', map { $_->to_string } @balance) . '>',
            '-'
          );
        };
      }

      # Current anno is smaller than i
      elsif ($anno->start < $i) {

        if (DEBUG) {
          print_log('kq_snippet', 'Add annotation to list ' . $anno->to_string . ' (3)');
        };

        push @list, $anno;
        unshift @balance, $anno;
        $anno = shift @$stack;

        if (DEBUG) {
          print_log(
            'kq_snippet',
            'Balance-Stack is <' . join('; ', map { $_->to_string } @balance) . '>',
            '-'
          );
        };

      }

      # Add data
      else {
        if (DEBUG) {
          print_log('kq_snippet', '2. Add text to list: ' . ($subterm ? $subterm : '-'));
        };
        push @list, _new_data($preceding) if $init++ && $preceding;
        push @list, _new_data(substr($subterm, 1)) if $subterm;
        ($preceding, $subterm) = $self->_subtoken(++$i);
      };
    }

    # Next tag is ending, but hasn't opened yet
    elsif (!$balance[0] && $anno->start_after_all) {

      if (DEBUG) {
        print_log('kq_snippet', 'Last element on stack is start-after-all');
      };

      # Create opening tag
      my $open = $anno->clone->is_opening(1);

      if (DEBUG) {
        print_log('kq_snippet', 'Add annotation to list ' . $open->to_string . ' (3 1/2)');
      };

      # Open tag immediately
      push @list, $open;

      # Balance
      unshift @balance, $open;
    }

    # Next tag is ending
    elsif ($anno->end > $i && ($subterm || $preceding)) {
      if (DEBUG) {
        print_log('kq_snippet', '3. Add text to list: ' . ($subterm ? $subterm : '-'));
      };
      push @list, _new_data($preceding) if $init++ && $preceding;
      push @list, _new_data(substr($subterm, 1)) if $subterm;
      ($preceding, $subterm) = $self->_subtoken(++$i);
    }

    # Add closing tag
    # - this requires something is on the balance stack
    elsif ($balance[0]) {

      # Check, if the annotation is balanced
      while (!$anno->resembles($balance[0])) {
        my $last = shift @balance;

        # Create closing element with a terminal marker,
        # indicating the element will be continued
        my $close = $last->clone->is_opening(0)->is_terminal(0);
        my $reopen = $last->clone->is_opening(1);

        if (DEBUG) {
          print_log(
            'kq_snippet',
            'Annotations are not balanced: ' .
              $anno->to_string . ' vs ' . $close->to_string
            );
          print_log(
            'kq_snippet',
            'Temporarily close ' . $close->to_string
          );
          print_log(
            'kq_snippet',
            'Balance-Stack is <' . join('; ', map { $_->to_string } @balance) . '>',
            '-'
          );
        };

        # TODO:
        #   Remove empty elements from stack (if they can occur!)

        unshift @temp_balance, $reopen;
        push @list, $close;

        if (DEBUG) {
          print_log('kq_snippet', 'Add annotation to list ' . $close->to_string . ' (4)');
        };

        last unless $balance[0];
      };

      if (DEBUG) {
        print_log('kq_snippet', 'Add annotation to list: ' . $anno->to_string . ' (5)');
      };

      push @list, $anno;
      shift @balance;

      # Reopen temporary closed elements
      # ??: unshift @balance, reverse @temp_balance;
      unshift @$stack, @temp_balance;

      if (DEBUG && @temp_balance) {
        print_log('kq_snippet', 'Add temporary balanced tags for reopening to balance');
        print_log(
          'kq_snippet',
          'Balance-Stack is <' . join('; ', map { $_->to_string } @balance) . '>',
          '-'
        );
      };

      @temp_balance = ();
      $anno = shift @$stack;

      if (DEBUG && $anno) {
        print_log(
          'kq_snippet',
          'Get next annotation from stack: ' . $anno->to_string
        )
      };
    }

    # There is something wrong
    else {
      warn 'Annotation is not fine ' . $anno->to_string;
      last;
    };
  };

  if (DEBUG) {
    print_log(
      'kq_snippet',
      'List of elements is ' . join('', map { $_->to_brackets } @list)
    );
  };

  return \@list;
};


# Get the highlight level based on a specific number
sub _get_level {
  my ($level_cache, $level_vector, $nr) = @_;

  if (DEBUG) {
    print_log('kq_snippet', 'Retrive level for class ' . $nr);
  };

  return '?' unless defined $nr;

  # Return defined level
  if ($level_cache->[$nr]) {
    return $level_cache->[$nr];
  };

  # Iterate unless an unused level is found
  foreach my $i (0..MAX_CLASS_NR) {

    # Check, if the level is not used yet
    if ($level_vector->[$i]) {

      if (DEBUG) {
        print_log('kq_snippet', "level $i is unused yet");
      };

      # Set level as "used"
      $level_vector->[$i] = 0;
      $level_cache->[$nr] = $i;
      return $i;
    };
  };

  return '?';
};


# Get subtoken at i
sub _subtoken {
  my ($self, $i) = @_;
  my $subtoken = $self->stream->[$i - $self->stream_offset];
  if (DEBUG && $subtoken) {
    print_log(
      'kq_snippet',
      'Fetch next subtoken "' .
        ($subtoken->preceding ? $subtoken->preceding : '') .
        '","' .
        ($subtoken->subterm ? $subtoken->subterm : '') .
        '"'
    );
  };
  return ($subtoken->preceding, $subtoken->subterm) if $subtoken;
  return ();
};


# Create new primary data object
sub _new_data {
  return Krawfish::Koral::Result::Enrich::Snippet::Primary->new(
    data => shift
  );
};


# Add annotation
sub add {
  my ($self, $e) = @_;

  if (DEBUG) {
    print_log('kq_snippet', 'Add markup ' . $e);
  };

  # Add markup objects
  if (Role::Tiny::does_role($e, 'Krawfish::Koral::Result::Enrich::Snippet::Markup')) {

    # Add the hit boundaries
    if ($e->isa('Krawfish::Koral::Result::Enrich::Snippet::Hit')) {
      $self->hit_start($e->start);
      $self->hit_end($e->end);
    }

    # Context information
    elsif ($e->isa('Krawfish::Koral::Result::Enrich::Snippet::Context')) {
      $self->context_start($e->start);
      $self->context_end($e->end);
    }

    # Scope extended by, e.g., spans
    elsif ($e->isa('Krawfish::Koral::Result::Enrich::Snippet::Focus')) {
      $self->focus_start($e->start);
      $self->focus_end($e->end);
    };

    # Push to annotation list
    push @{$self->{annotations}}, $e;
  };
};


# Remove all annotations
sub reset_annotations {
  my $self = shift;
  $self->{annotations} = [];
  return $self;
};


# Set context start position
sub context_start {
  my $self = shift;
  if (@_) {
    $self->{context_start} = shift;
    return $self;
  };
  return $self->{context_start};
};


# Set context end position
sub context_end {
  my $self = shift;
  if (@_) {
    $self->{context_end} = shift;
    return $self;
  };
  return $self->{context_end};
};


# Set extension start position
sub focus_start {
  my $self = shift;
  if (@_) {
    $self->{focus_start} = shift;
    return $self;
  };
  return $self->{focus_start};
};


# Set extension end position
sub focus_end {
  my $self = shift;
  if (@_) {
    $self->{focus_end} = shift;
    return $self;
  };
  return $self->{focus_end};
};


# Set hit start position
sub hit_start {
  my $self = shift;
  if (@_) {
    $self->{hit_start} = shift;
    return $self;
  };
  return $self->{hit_start};
};


# Set hit end position
sub hit_end {
  my $self = shift;
  if (@_) {
    $self->{hit_end} = shift;
    return $self;
  };
  return $self->{hit_end};
};


1;
