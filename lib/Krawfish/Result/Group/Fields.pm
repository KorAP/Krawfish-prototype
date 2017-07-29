package Krawfish::Result::Group::Fields;
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
  bless {
    index => shift,
    fields => shift,
    groups => {},
    ranks => undef,

    # Store all example docs per field position at rank position
    # in a hash [[example_doc_nr,example_doc_nr,...], [...], ...]
    example_docs => undef
  }, $class;
};


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

sub to_string {
  my $str = 'fields';
  $str .= '[' . join(',', @{$_[0]->{fields}}) . ']';
  return $str;
};


1;
