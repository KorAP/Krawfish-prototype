package Krawfish::Result::Segment::Aggregate::ClassFrequencies;
use parent 'Krawfish::Result::Segment::Aggregate::Base';
use Krawfish::Posting::Aggregate::ClassFrequencies;
use Krawfish::Log;
use strict;
use warnings;

use constant DEBUG => 1;

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


sub new {
  my $class = shift;
  bless {
    forward_obj => shift,
    classes => [@_],
    class_freq => {},
    term_cache => {},
    aggregation => Krawfish::Posting::Aggregate::ClassFrequencies->new
  }, $class;
};


# Initialize forward counter
sub _init {
  return if $_[0]->{forward_pointer};

  my $self = shift;

  print_log('aggr_class', 'Create forward pointer') if DEBUG;

  # Load the ranked list - may be too large for memory!
  $self->{forward_pointer} = $self->{forward_obj}->pointer;
};


# Move to next matching document
sub each_doc {
  my ($self, $current) = @_;

  # Get the current doc_id and move to it
  my $doc_id = $current->doc_id;

  my $pointer = $self->{forward_pointer};

  # Clear term cache
  %{$self->{term_cache}} = ();

  # Skip to doc
  if ($pointer->skip_doc($doc_id) != $doc_id) {

    # This should never happen, as for all docs there is a
    # forward index!
    return;
  };

  return 1;
};


# Collect all matching classes in the doc
sub each_match {
  my ($self, $current) = @_;

  my $pointer = $self->{forward_pointer};

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

  # Retrieve the requested classes for the current posting
  foreach my $class_info ($current->get_classes($self->{classes})) {

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

          # Set term_id at relative position in term_cache
          $term_cache[$rel_pos] = $classes[$nr]->[$rel_pos] = $term_id;
        };
      }

    };
  };

  # The signature has the structure [class, term_id*]+
  my @sig = ();

  # Iterate over all classes
  foreach my $nr (@{$self->{classes}}) {
    push @sig, $nr;

    foreach ($classes) {
      push @sig, $_ if $_; # Add all set term_ids
    };

    push @sig, 0;
  };

  # Increment per match
  $self->{aggregation}->incr_match(join('-',@sig));
};


1;
