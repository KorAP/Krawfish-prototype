package Krawfish::Compile::Segment::Group::ClassFrequencies;
use Krawfish::Koral::Result::Group::ClassFrequencies;
use Krawfish::Log;
use strict;
use warnings;
use Role::Tiny::With;

with 'Krawfish::Compile::Segment::Group';

use constant DEBUG => 0;

# Aggregate by content information, for example,
# based on a certain class
#
# TODO:
#   Currently this only works for surface term_ids, but it may very well collect
#   arbitrary annotations! In that case, multiple annotations and different
#   annotation lengths have to be taken into account.
#
# TODO:
#   The special case of class 0 needs to be treated.
#
# TODO:
#   Support virtual corpus classes

sub new {
  my $class = shift;
  my $self = bless {
    forward_obj => shift,
    query       => shift,
    classes     => shift,
    class_freq  => {},
    term_cache  => {},
    last_doc_id => -1
  }, $class;

  $self->{groups} = Krawfish::Koral::Result::Group::ClassFrequencies->new(
    $self->{classes}
  );

  return $self;
};


# Initialize forward counter
sub _init {
  return if $_[0]->{forward_pointer};

  my $self = shift;

  print_log('g_class_freq', 'Create forward pointer') if DEBUG;

  # Load the ranked list - may be too large for memory!
  $self->{forward_pointer} = $self->{forward_obj}->pointer;
};


sub clone {
  ...
};


# Move to next match
sub next {
  my $self = shift;

  $self->_init;

  # No more matches
  return unless $self->{query}->next;

  # Get the current posting
  my $current = $self->{query}->current;

  my $groups = $self->{groups};
  my $pointer = $self->{forward_pointer};

  # Get the current doc_id and move to it
  my $doc_id = $current->doc_id;

  # Current doc_id differ - move forward
  if ($doc_id != $self->{last_doc_id}) {

    # Skip to doc
    if ($pointer->skip_doc($doc_id) != $doc_id) {

      # This should never happen, as for all docs there is a
      # forward index!
      return;
    };

    if (DEBUG) {
      print_log('g_class_freq', "Moved forward index to $doc_id");
    };

    # Remember the last document
    $self->{last_doc_id} = $doc_id;
  };

  # Remember terms (for overlap)
  # with the structure pos -> term_id
  # my $cache = $self->{term_cache};

  # Collect classes - have the structure
  # $classes[1] = [...term_id,0,0,term_id,...]
  my @classes = ();
  foreach (@{$self->{classes}}) {
    $classes[$_] = []; # TODO: Length is normally the length of the match
  };
  my @term_cache = ();

  # Get offset to simplify classes
  my $offset = $current->start;

  # TODO:
  #   There may be overlaps within following
  #   matches, so under certain circumstances the pointer
  #   needs to move backwards.
  #   It may be enough to do that at the beginning here.
  #   Or instead of skip_pos, the forward pointer can
  #   reposition automatically.

  # Get class payloads
  my @class_infos = $current->query_classes($self->{classes});

  # Retrieve the requested classes for the current posting
  foreach my $class_info (@class_infos) {

    # Check class info
    my ($nr, $start, $end) = @{$class_info};

    # Iterate over the class and collect term ids
    for (my $i = $start; $i < $end; $i++) {

      # The relative position of the class in the match
      my $rel_pos = $i - $offset;

      # Check if term already retrieved
      if ($term_cache[$rel_pos]) {

        # Copy to class
        $classes[$nr]->[$rel_pos] = $term_cache[$rel_pos];
      }

      # TODO:
      #   Check for term cache
      #   if ($term_cache->{$start})

      # Retrieve term id
      else {

        # Collect all terms from start to end
        if ($pointer->skip_pos($i)) {

          # Add term id to class in correct order
          my $term_id = $pointer->current->term_id;

          if (DEBUG) {
            print_log(
              'g_class_freq',
              "Term id at position $i is #" . $term_id);
          };


          # Set term_id at relative position in term_cache
          $term_cache[$rel_pos] = $classes[$nr]->[$rel_pos] = $term_id;
        };
      }
    };
  };

  if (DEBUG) {
    print_log('g_class_freq', 'term cache is ' . join(',', @term_cache));
  };

  # The signature has the structure [class, term_id*]+
  my @sig = ();

  # Iterate over all classes
  foreach my $nr (@{$self->{classes}}) {
    push @sig, $nr;

    foreach (@{$classes[$nr]}) {
      push @sig, $_ if defined $_; # Add all set term_ids
    };

    push @sig, 0;
  };

  # Increment per match
  $self->{groups}->incr_match(\@sig);

  return 1;
};


sub current {
  return $_[0]->{query}->current;
};


# Get collection
sub collection {
  $_[0]->{groups};
};


sub to_string {
  my $self = shift;
  my $str = 'gClassFreq(' . join(',', @{$self->{classes}}) .
    ':' . $self->{query}->to_string . ')';
  return $str;
};

1;
