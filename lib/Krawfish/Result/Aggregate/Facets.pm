package Krawfish::Result::Aggregate::Facets;
use parent 'Krawfish::Result::Aggregate::Base';
use Krawfish::Log;
use strict;
use warnings;

use constant DEBUG => 0;

# TODO: It may be beneficial to store example documents in the
#   field ranks, too - so they don't need to be collected on the way ...
#   See Group::Fields as well.
#
# TODO:
#   Field aggregates should be sortable either <asc> or <desc>,
#   and should have a count limitation, may be even a start_index and an items_per_page

sub new {
  my $class = shift;
  my $self = bless {
    index   => shift,
    field   => shift,

    # TODO: May as well be groups ...
    buckets => [], # The buckets in memory
    freq    => undef
  }, $class;
};

sub _init {
  return if $_[0]->{rank};

  my $self = shift;

  print_log('aggr_facets', 'Load ranks for ' . $self->{field}) if DEBUG;

  # Load the ranked list - may be too large for memory!
  $self->{rank} = $self->{index}->fields->ranked_by($self->{field});
};


# On every doc
sub each_doc {
  my $self = shift;
  $self->_init;
  my $current = shift;

  my $doc_id = $current->doc_id;

  # Get the document rank
  my $rank = $self->{rank}->get($doc_id);

  # Rank exists
  # TODO:
  #   Check if zero don't mean, the field
  #   is not ranked yet!
  if ($rank != 0) {

    # This will contain 'doc_freq', 'freq', and an example 'doc_id'
    $self->{freq} = $self->{buckets}->[$rank] //= [0,0, $doc_id];
    $self->{freq}->[0]++;

    print_log('aggr_facets', $self->{field} . ' has frequencies') if DEBUG;
  }

  # Do not check rank
  else {
    $_[0]->{freq} = undef;
  };
};


# On every match
sub each_match {
  if ($_[0]->{freq}) {
    $_[0]->{freq}->[1]++;
  };
};


# finish the results
sub on_finish {
  my ($self, $result) = @_;

  # Get fields
  my $fields = $self->{index}->fields;
  my $field = $self->{field};

  my %facets = ();

  # Iterate over all ranked buckets of the field
  foreach my $rank (grep { defined $_ } @{$self->{buckets}}) {

    print_log('aggr_facets', "Get rank $rank for $field") if DEBUG;

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
  my $facet_result = ($result->{facets} //= {});
  $facet_result->{$self->{field}} = \%facets;
};

sub to_string {
  return 'facet:' . _squote($_[0]->{field});
};


# From Mojo::Util
sub _squote {
  my $str = shift;
  $str =~ s/(['\\])/\\$1/g;
  return qq{'$str'};
};


1;
