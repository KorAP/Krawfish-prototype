package Krawfish::Result::Aggregate::Facets;
use Krawfish::Log;
use strict;
use warnings;

use constant DEBUG => 0;

sub new {
  my $class = shift;
  my $self = bless {
    index   => shift,
    field   => shift,
    buckets => [], # The buckets in memory
    freq    => undef
  }, $class;
};

sub _init {
  return if $_[0]->{rank};

  my $self = shift;

  print_log('pdoc_facets', 'Load ranks for ' . $self->{field}) if DEBUG;

  # Load the ranked list - may be too large for memory!
  $self->{rank} = $self->{index}->fields->ranked_by($self->{field});
};


# Only preload if necessary
sub each_doc {
  my $self = shift;
  $self->_init;

  my $current = shift;

  my $doc_id = $current->doc_id;
  my $rank = $self->{rank}->get($doc_id);

  if ($rank != 0) {

    # This will contain 'doc_freq', 'freq', and an example 'doc_id'
    $self->{freq} = $self->{buckets}->[$rank] //= [0,0, $doc_id];
    $self->{freq}->[0]++;

    print_log('pmatch_facets', $self->{field} . ' has frequencies') if DEBUG;
  }

  # Do not check rank
  else {
    $_[0]->{freq} = undef;
  };
};


sub each_match {
  if ($_[0]->{freq}) {
    $_[0]->{freq}->[1]++;
  };
};


sub facets {
  my $self = shift;

  # Fields
  my $fields = $self->{index}->fields;
  my $field = $self->{field};

  my %facets = ();

  # Iterate over all ranked buckets of the field
  foreach my $rank (grep { defined $_ } @{$self->{buckets}}) {

    print_log('pmatch_facets', "Get rank $rank for $field") if DEBUG;

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

sub to_string {
  return 'facet:' . $_[0]->{field};
};

sub result {
  my $self = shift;
  return {
    facets => {
      $self->{field} => $self->facets
    }
  };
};

1;
