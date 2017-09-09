package Krawfish::Result::Segment::Group::Fields;
use parent 'Krawfish::Result';
use Krawfish::Posting::Group::Fields;
use Krawfish::Log;
use strict;
use warnings;

use constant DEBUG => 0;

# This will group matches (especially document matches) by field
# This is useful e.g. for document browsing per corpus.
#
# Because the grouping is based on ranking, the sorting will be trivial.
#
# TODO:
#   For some mechanisms, it is not necessary to count all occurrences,
#   e.g. to get all keywords used in a certain virtual corpus or all
#   used annotations.

sub new {
  my $class = shift;
  my ($field_obj, $query, $fields) = @_;
  my $self = bless {
    field_obj  => $field_obj,
    query      => $query,
    field_keys => [map { ref($_) ? $_->term_id : $_ } @$fields],
    last_doc_id => -1
  }, $class;

  # Initialize group object
  $self->{groups} = Krawfish::Posting::Group::Fields->new($self->{field_keys});

  return $self;
};


# Initialize field pointer
sub _init {
  return if $_[0]->{field_pointer};

  my $self = shift;

  print_log('g_fields', 'Create pointer on fields') if DEBUG;

  # Load the ranked list - may be too large for memory!
  $self->{field_pointer} = $self->{field_obj}->pointer;
};


sub to_string {
  my $self = shift;
  my $str = 'gFields(' . join(',', map { '#' . $_ } @{$self->{field_keys}}) .
    ':' . $self->{query}->to_string . ')';
  return $str;
};


# Shorthand for "search through"
sub finalize {
  while ($_[0]->next) {};
  return $_[0];
};


# Iterate to the next result
sub next {
  my $self = shift;

  $self->_init;

  my $groups = $self->{groups};
  my $pointer = $self->{field_pointer};

  # There is a next match
  if ($self->{query}->next) {

    # Get the current posting
    my $current = $self->{query}->current;

    if ($current->doc_id != $self->{last_doc_id}) {

      # Flush old information
      $groups->flush;

      my $doc_id = $pointer->skip_doc($current->doc_id);

      # There are no fields for this doc
      next if $doc_id != $current->doc_id;

      # Due to multivalued fields,
      # a document can yield a permutation of
      # patterns, so we recognize this
      my @patterns = ();
      my @field_keys = @{$self->{field_keys}};

      # Ignore stored fields
      my @field_objs = grep { $_->type ne 'store' } $pointer->fields(@field_keys);

      my ($key_pos, $val_pos) = (0,0);

      # Iterate through both lists and create a pattern
      # Pattern may occur because fields can have multiple values
      while ($key_pos < @field_keys) {

        # There are no more values for the position
        if (!$field_objs[$val_pos]) {
          # Add ignorable null term
          unless (@{$patterns[$key_pos]}) {
            push @{$patterns[$key_pos]}, 0;
          };
          $key_pos++;
        }

        # Key identifier are matching
        elsif ($field_keys[$key_pos] == $field_objs[$val_pos]->key_id) {

          # Add key to pattern
          $patterns[$key_pos] //= [];
          push @{$patterns[$key_pos]}, $field_objs[$val_pos]->term_id;
          $val_pos++;
        }

        # Forward key position
        elsif ($field_keys[$key_pos] < $field_objs[$val_pos]->key_id) {

          # Add ignorable null term
          unless (@{$patterns[$key_pos]}) {
            push @{$patterns[$key_pos]}, 0;
          };
          $key_pos++;
        }

        # $field_keys[$key_pos] > $field_objs[$val_pos]->key_id
        else {

          # I don't know if this can happen
          $val_pos++;
        };
      };

      # This adds
      $groups->incr_doc(\@patterns);

      # Set last doc to current doc
      $self->{last_doc_id} = $current->doc_id;
    };

    # Add to frequencies
    $groups->incr_match;

    return 1;
  };

  # Flush cached results
  $groups->flush;

  return 0;
};


sub current {
  return $_[0]->{query}->current;
};


# Get collection
sub collection {
  $_[0]->{groups};
};


1;


__END__
