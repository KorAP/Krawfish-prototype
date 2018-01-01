package Krawfish::Koral::Result::Enrich::Snippet;
use strict;
use warnings;
use Krawfish::Util::Constants ':PREFIX';
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
  return $self;
};


# Inflate term ids to terms
sub inflate {
  my ($self, $dict) = @_;

  # Inflate the stream
  $self->stream($self->stream->inflate($dict));

  #my $hit = $self->{hit_ids};
  #for (my $i = 0; $i < @$hit; $i++) {
  #  $hit->[$i] = $hit->[$i]->inflate($dict);
  #};
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


# Key for KQ serialization
sub key {
  'snippet'
};


# Serialize KQ
sub to_koral_fragment {
  my $self = shift;

  return $self->stream->to_string
};


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

  # 2. Sort the closing tags
  my @open = sort {

    # Sort for opening tags
    $a->compare_open($b)
  } @{$self->{annotations}};

  # 3. Sort the closing tags
  my @close = sort {

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


# Iterate over all annotations and join with stream
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

  # TODO:
  #   Take care of preceding data

  # TODO:
  #   Take care of stream_offset
  my $anno = shift @$stack;
  while ($i < $length || $anno) {

    my $subtoken = $stream->[$i - $self->stream_offset];

    # No more annotations
    unless ($anno) {

      if ($subtoken && $subtoken->subterm) {
        if (DEBUG) {
          print_log('kq_snippet', 'Add text to list ' . $subtoken->subterm);
        };
        push @list, _new_data(substr($subtoken->subterm, 1));
      };
      $i++;

    # Add opening tag
    }

    elsif ($anno->is_opening) {

      # Add annotation start tag
      if ($anno->start <= $i) {
        if (DEBUG) {
          print_log('kq_snippet', 'Add annotation to list ' . $anno->to_string);
        };
        push @list, $anno;
        $anno = shift @$stack;
      }

      # Add data
      else {
        if ($subtoken && $subtoken->subterm) {
          if (DEBUG) {
            print_log('kq_snippet', 'Add text to list ' . $subtoken->subterm);
          };
          push @list, _new_data(substr($subtoken->subterm, 1));
        };
        $i++;
      };
    }

    # Deal with closing tag
    elsif ($anno->end > $i) {
      if ($subtoken && $subtoken->subterm) {
        if (DEBUG) {
          print_log('kq_snippet', 'Add text to list: ' . $subtoken->subterm);
        };
        push @list, _new_data(substr($subtoken->subterm, 1));
      };
      $i++;
    }

    # Add closing tag
    else {

      # TODO:
      #   This needs to take care of balancing elements,
      #   so overlaps will work as expected
      if (DEBUG) {
        print_log('kq_snippet', 'Add annotation to list: ' . $anno->to_string);
      };

      push @list, $anno;
      $anno = shift @$stack;
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


# Create new primary data object
sub _new_data {
  return Krawfish::Koral::Result::Enrich::Snippet::Primary->new(
    data => shift
  );
};


# Add annotation
sub add {
  my $self = shift;
  my $e = shift;

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
