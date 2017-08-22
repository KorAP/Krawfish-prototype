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

  # Get container object
  # my $collection = $self->collection;

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

      # TODO: Add lists
      # $self->{current_group} = $groups->add();

      # Set last doc to current doc
      $self->{last_doc_id} = $current->doc_id;
    };

    # Add to frequencies
    $groups->incr_match;

    return 1;
  };

  # Release on_finish event
  #unless ($self->{finished}) {
  #  foreach (@{$self->{ops}}) {
  #    $_->on_finish($collection);
  #  };
  #  $self->{finished} = 1;
  #};

  $groups->flush;

  return 0;
};


sub current {
  return $_[0]->{query}->current;
};


sub collection {
  $_[0]->{groups};
};


sub on_finish {
  my ($self, $collection) = @_;
  $self->{groups}->flush;
  $collection->{fields} = $self->{groups};
};


1;
__END__


# Initialize group fetching
sub _init {
  return if $_[0]->{ranks};

  my $self = shift;

  print_log('group_fields', 'Get ranks for fields') if DEBUG;

  # Get fields object
  my $fields = $self->{index}->fields;

  # Lift ranks for each relevant field
  # (may already be liftet for another job ...)
  # and initialize example docs
  my $ranks         = ($self->{ranks} = []);
  my $example_docs = ($self->{example_docs} = []);
  my $i = 0;
  my @fields = ();
  foreach my $field (@{$self->{fields}}) {

    print_log('group_fields', "Lift the ranks for '$field'") if DEBUG;

    # Fetch rank
    if (my $rankings = $fields->ranked_by($field)) {
      push @$ranks, $rankings;
      $self->{example_docs}->[$i] = [];
      push @fields, $field;
    };

    $i++;
  };

  # In case they were no-ranked fields requested, the field request needs to be rewritten.
  # WARNING: This needs to be notified to the user somehow ...
  $self->{fields} = \@fields;
};


# Get the group signature for each match
# May well be renamed to "get_signature"
sub get_group {
  my $self = shift;
  $self->_init;

  my $current = shift;
  my $doc_id = $current->doc_id;

  # Create a string with all necessary field information
  my @group = ();
  my $i = 0;
  my $example_docs = $self->{example_docs};

  # Iterate over all rankings
  foreach my $rankings (@{$self->{ranks}}) {

    # Get the rank of the match
    my $rank = $rankings->get($doc_id);

    # Store example document to later retrieve surface field
    $example_docs->[$i++]->[$rank] //= $doc_id;

    # push rank to signature
    push @group, $rank;
  };

  # Create signature string
  return join('___',  @group);
};


# return group info as hash
sub to_hash {
  my ($self, $signature, $doc_freq, $freq) = @_;

  # Get field titles
  my $fields = $self->{fields};
  my $fields_obj = $self->{index}->fields;
  my $example_docs = $self->{example_docs};

  # Get field values
  my @ranks = split('___', $signature);

  # Store frequency information
  my %hash = (
    doc_freq => $doc_freq
  );
  $hash{freq} = $freq if defined $freq;

  print_log('group_field', "Create hash for $signature") if DEBUG;

  # Iterate over all ranks in the signature
  # - this will be identical to the number of fields requested
  for (my $i = 0; $i < scalar @ranks; $i++) {

    # Get rankings
    my $rank = $ranks[$i];

    my $doc_id = $example_docs->[$i]->[$rank];

    print_log('group_field', "Example doc is $doc_id") if DEBUG;

    # Get field title
    my $field_title = $fields_obj->get(
      $example_docs->[$i]->[$rank],
      $fields->[$i]
    );

    # Set field title and value
    $hash{$fields->[$i]} = $field_title;
  };

  return \%hash;
};



1;
