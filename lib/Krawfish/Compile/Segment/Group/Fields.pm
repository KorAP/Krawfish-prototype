package Krawfish::Compile::Segment::Group::Fields;
use Krawfish::Koral::Result::Group::Fields;
use Krawfish::Util::Constants qw/NOMOREDOCS/;
use Krawfish::Log;
use strict;
use warnings;
use Role::Tiny::With;

with 'Krawfish::Compile::Segment::Group';

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

# TODO:
#   In case the field has ranges, this will increment the group
#   values for the whole range.

# TODO:
#   Theoretically the frequency counting could also be done
#   using frequency group aggregation, but this would probably
#   be slower ... though - it would be way cleaner and may
#   be useful in case grouping without frequency information
#   is wanted.

sub new {
  my $class = shift;

  # TODO:
  #   Use a hash!
  my ($field_obj, $query, $fields, $aggr) = @_;
  my $self = bless {
    field_obj  => $field_obj,
    query      => $query,
    field_keys => $fields,
    aggr       => $aggr,

    last_doc_id => -1,
    finished   => 0
  }, $class;

  # Initialize group object
  $self->{group} = Krawfish::Koral::Result::Group::Fields->new($self->{field_keys});

  return $self;
};


# The Aggregation object is of type Group::Aggregate
sub aggregation {
  my ($self, $aggr) = @_;
  if ($aggr) {
    $self->{aggr} = $aggr;
    return $self;
  };
  return $self->{aggr};
};


# Clone query
sub clone {
  my $self = shift;
  return __PACKAGE__->new(
    $self->{field_obj},
    $self->{query},
    $self->{field_keys},
    $self->{aggr} ? $self->{aggr}->clone : undef
  );
};


# Initialize field pointer
sub _init {
  return if $_[0]->{field_pointer};

  my $self = shift;

  print_log('g_fields', 'Create pointer on fields') if DEBUG;

  # Load the ranked list - may be too large for memory!
  $self->{field_pointer} = $self->{field_obj}->pointer;
};


# Stringification
sub to_string {
  my ($self, $id) = @_;

  my $str = 'gFields(';
  $str .= join(',', map { $_->to_string($id) } @{$self->{field_keys}});

  if ($self->{aggr}) {
    $str .= ';'. $self->{aggr}->to_string;
  };

  $str .= ':' . $self->{query}->to_string($id) . ')';
  return $str;
};


# Iterate to the next result
sub next {
  my $self = shift;

  $self->_init;

  my $group = $self->{group};
  my $aggr = $self->{aggr};
  my $pointer = $self->{field_pointer};

  # There is a next match
  if ($self->{query}->next) {

    # Get the current posting
    my $current = $self->{query}->current;

    # The new match is not in the same document
    if ($current->doc_id != $self->{last_doc_id}) {

      # Flush old information
      $group->flush;

      my $doc_id = $pointer->skip_doc($current->doc_id);

      # There are no more field docs
      last if $doc_id == NOMOREDOCS;

      # There are no fields for this doc
      next if $doc_id != $current->doc_id;

      # Remember flags
      my $flags = $current->flags($self->{flags});

      # Due to multivalued fields,
      # a document can yield a permutation of
      # patterns, so we recognize this
      my @patterns = ();
      my @field_keys = @{$self->{field_keys}};

      # Ignore stored fields
      my @field_objs = grep { $_->type ne 'store' } $pointer->fields(
        map { $_->term_id } @field_keys
      );

      # TODO:
      #   Skip term id #0

      my ($key_pos, $val_pos) = (0,0);

      # Iterate through both lists and create a pattern
      # Pattern may occur because fields can have multiple values
      while ($key_pos < @field_keys) {

        # There are no more values for the position
        if (!$field_objs[$val_pos]) {

          # Add ignorable null term
          if (!$patterns[$key_pos] || !@{$patterns[$key_pos]}) {
            $patterns[$key_pos] = [0]
          };

          $key_pos++;
        }

        # Key identifier are matching
        elsif ($field_keys[$key_pos]->key_id == $field_objs[$val_pos]->key_id) {

          if (DEBUG) {
            print_log(
              'g_fields',
              'Key at ' . $key_pos . ' is ' . $field_keys[$key_pos]->key_id .
                ' which is equal to ' . $field_objs[$val_pos]->key_id);
          };

          # Add key to pattern
          $patterns[$key_pos] //= [];
          push @{$patterns[$key_pos]}, $field_objs[$val_pos]->term_id;
          $val_pos++;
        }

        # Forward key position
        elsif ($field_keys[$key_pos]->key_id < $field_objs[$val_pos]->key_id) {

          if (DEBUG) {
            print_log(
              'g_fields',
              'Key at ' . $key_pos . ' is ' . $field_keys[$key_pos]->key_id .
                ' which is smaller than ' . $field_objs[$val_pos]->key_id);
          };

          # Add ignorable null term
          # Pattern is not yet initialized
          if (!$patterns[$key_pos] || !@{$patterns[$key_pos]}) {
            $patterns[$key_pos] = [0]
          };
          $key_pos++;
        }

        # $field_keys[$key_pos] > $field_objs[$val_pos]->key_id
        else {

          # I don't know if this can happen
          $val_pos++;
        };
      };

      # This adds a doc based on pattern
      $group->incr_doc(\@patterns, $flags);

      # TODO:
      #   each_doc(...);

      # Set last doc to current doc
      $self->{last_doc_id} = $current->doc_id;
    };

    # Add to frequencies
    $group->incr_match;

    # TODO:
    #   each_matchx(...);

    return 1;
  };

  # Release on_finish event
  unless ($self->{finished}) {
    $self->group->on_finish;
    $self->{finished} = 1;
  };

  return 0;
};


1;


__END__
