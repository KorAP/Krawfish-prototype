package Krawfish::Meta::Segment::Enrich::Terms;
use Krawfish::Koral::Result::Enrich::Terms;
use parent 'Krawfish::Meta';
use Krawfish::Log;
use strict;
use warnings;

# TODO:
#   Potentially rename to ::Terms!

# Enrich each match with all term ids for a specific region and
# for a specific class

# TODO:
#   Make this usable for Krawfish::Meta::Group::Classes
#   and Krawfish::Meta::Sort::Classes
#   by supporting $nrs instead of $nr
#
# TODO:
#   Classes may overlap, so subtokens should be cached/buffered
#   or rather memoized!
#   This also means it's necessary to retrieve term-ids without gaps
#   so the next match can retrieve the term ids overlapping
#
# TODO:
#   For a class there may be more than one start+end values.
#   For sorting, gaps should be recognized and marked
#   with a term_id=0.
#   For sorting it's important to remember that!

use constant {
  DEBUG     => 1,
  NR        => 0,
  START_POS => 1,
  END_POS   => 2,
};


sub new {
  my $class = shift;
  bless {
    forward_obj => shift,
    query => shift,
    nrs   => shift // [0],
    match => undef
  }, $class;
};

sub to_string {
  my $self = shift;
  'terms(' . join(',', @{$self->{nrs}}) . ':'
    . $self->{query}->to_string . ')'
};


sub _init {
  my $self = shift;

  return if $self->{init}++;

  if (DEBUG) {
    print_log(
      'r_terms',
      'Initiate pointer to forward index'
    );
  };

  # The pointer can move backwards if necessary
  $self->{pointer} = $self->{forward_obj}->pointer;
};


sub pointer {
  $_[0]->{pointer};
};



# Next match
sub next {
  my $self = shift;
  $self->{match} = undef;
  return $self->{query}->next;
};


# Get the current match
sub current_match {
  my $self = shift;

  $self->_init;

  # Current match is already defined
  if ($self->{match}) {

    # Return match
    return $self->{match};
  };

  # Get match based on current query position
  my $match = $self->match_from_query;

  if (DEBUG) {
    print_log(
      'r_terms',
      'Get match from query'
    );
  };

  # Get classes of the match
  my @classes = $match->get_classes($self->{nrs});

  # No classes found in match
  return $match unless @classes;

  # This only contains classes requested,
  # but potentially multiple times

  # First retrieve term ids
  my $start = $classes[0]->[START_POS];
  my $end   = $classes[0]->[END_POS];
  foreach (@classes[1 .. $#classes]) {
    $start = $_->[START_POS] if $_->[START_POS] < $start;
    $end = $_->[END_POS] if $_->[END_POS] > $end;
  };

  if (DEBUG) {
    print_log(
      'r_terms',
      "Retrieve subtokens for class position $start-$end"
    );
  };

  # TODO:
  #   Instead of using pointer directly,
  #   this should use a forward buffer
  #   with a yet to be defined API

  my $pointer = $self->pointer;

  # Skip to current document
  my @term_ids = ();

  my $doc_id = $match->doc_id;
  if ($pointer->skip_doc($doc_id) == $doc_id &&

        # Skip to current position
        $pointer->skip_pos($start)) {

    if (DEBUG) {
      print_log('r_terms', "Pointer is repositioned");
    };


    # Collect all relevant subtoken term ids
    for (my $i = $start; $i < $end; $i++) {
      # Add terms to list
      my $current = $pointer->current or return $match;
      push @term_ids, $current->term_id;

      # Move to next subtoken
      $pointer->next;
    };
  }

  # Document not available
  else {
    # Nothing to add
    return $match;
  };

  if (DEBUG) {
    print_log(
      'r_terms',
      'Retrieved terms are ' . join(',', @term_ids)
    );
  };

  # Add lists of term_ids
  # Structure is
  # {
  #   class1 => [id,id,0,id,id],
  #   class2 => [...]
  # }
  # WARNING:
  #   Gaps in classes are marked with 0!
  my %term_id_per_class;
  foreach my $class (@classes) {

    if (DEBUG) {
      print_log(
        'r_terms',
        'Add term ids for class ' . $class->[NR] .
          ' with theoretical start at ' . $start
      );
    };

    # Get the term vector of the class
    my $term_ids = ($term_id_per_class{$class->[NR]} //= []);

    # Foreach position, set the term_id
    foreach my $pos ($class->[START_POS] .. ($class->[END_POS] - 1)) {

      # Get the position without offset
      $pos = $start - $pos;

      # Copy the term id from the retrieved list
      $term_ids->[$pos] = $term_ids[$pos];
    };
  };

  # Because this may introduce zeros at the beginning,
  # all classes need to be trimmed again
  foreach my $class_nr (keys %term_id_per_class) {
    while (defined $term_id_per_class{$class_nr}->[0] &&
             $term_id_per_class{$class_nr}->[0] == 0) {
      shift @{$term_id_per_class{$class_nr}};
    };
  };

  # Add term id information per class
  $match->add(
    Krawfish::Koral::Result::Enrich::Terms->new(
      \%term_id_per_class
    )
  );

  # Set match
  $self->{match} = $match;
};



1;
