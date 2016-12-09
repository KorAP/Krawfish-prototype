package Krawfish::Search::FieldFacets;
use Krawfish::Log;
use strict;
use warnings;

use constant DEBUG => 0;

# This search construct will collect frequencies for fields
# in buckets to make facet search possible

# TODO:
#   This should - as a by product - count frequencies

sub new {
  my $class = shift;
  my $self = bless {
    query => shift,
    index => shift,
    facet_fields => shift,
    buckets => {}, # The buckets in memory
    ranks => {},    # The ranked lists - may be too large for memory!
    doc_id => undef
  }, $class;

  my $query = $self->{query};

  # Fields
  my $fields = $self->{index}->fields;

  # Preload ranks
  foreach (@{$self->{facet_fields}}) {

    print_log('facet', 'Preload field_rank for ' . $_) if DEBUG;

    # These may already be loaded in memory (for facets or sorting)
    (my $max_rank, $self->{ranks}->{$_}) = $fields->docs_ranked($_);
  };

  return $self;
};


# This may be either a corpus query or a doc query
sub next {
  my $self = shift;

  my $field;

  # Next query
  if ($self->{query}->next) {
    my $current = $self->{query}->current;
    my $doc_id = $current->doc_id;
    my $last_doc_id = $self->{doc_id};

    print_log('facet', "Get facet info for $doc_id") if DEBUG;

    # Iterate over all fields and collect ranks
    foreach $field (@{$self->{facet_fields}}) {

      # Get rank for field
      my $rank = $self->{ranks}->{$field}->[$doc_id];
      # The rank may be ordered ordinally or lexicographic

      print_log('facet', "  '$field' has rank $rank") if DEBUG;

      # Field exists for document
      if ($rank != 0) {

        # Get the field bucket from memory
        my $bucket = ($self->{buckets}->{$field} //= []);

        print_log('facet', '  bucket is initialized') if DEBUG;

         # This will contain 'doc_freq', 'freq', and an example 'doc_id'
        my $freq_bucket = $bucket->[$rank] //= [0, 0, $doc_id];

        # Increment information
        if (!defined($last_doc_id) || $last_doc_id != $doc_id) {

          # Increment document frequency
          $freq_bucket->[0]++;
        };

        # Increment occurrence frequency
        $freq_bucket->[1]++;
        print_log(
          'facet',
          "  '$field' has frequencies " .
            $freq_bucket->[0] . '/' . $freq_bucket->[1]
        ) if DEBUG;
      };
    };

    $self->{doc_id} = $doc_id;
    return 1;
  };

  return;
};


sub current {
  return $_[0]->{query}->current;
};


# Return the collected facets
sub facets {
  my ($self, $field) = @_;

  # Get collected buckets per field
  my $bucket = $self->{buckets}->{$field};

  my %facets = ();

  # Fields
  my $fields = $self->{index}->fields;

  # Iterate over all ranked buckets of the field
  foreach my $rank (grep { defined $_ } @$bucket) {

    print_log('facet', "Get rank $rank for $field") if DEBUG;

    # Get information from rank
    my ($doc_freq, $freq, $example_doc_id) = @$rank;

    # This rank occurrs in the query
    if ($doc_freq) {

      # Get the field name of the frequency
      my $field_value = $fields->get($example_doc_id, $field);

      # Set facet information
      # May need the field key prepended
      $facets{$field_value} = [$doc_freq, $freq];
    };
  };

  # Return facets
  # Example structure for year
  # {
  #   1997 => [4, 67],
  #   1998 => [5, 89],
  #   1999 => [3, 20]
  # }
  return \%facets;
};

1;
