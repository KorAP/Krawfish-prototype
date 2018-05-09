package Test::Krawfish::DateRanges;
use Krawfish::Koral::Document::Field::DateRange;
use Krawfish::Koral::Corpus::Field::Date;
use Krawfish::Koral::Corpus::DateRange;
use Krawfish::Util::Constants qw/DATE_FIELD_PREF/;
use Krawfish::Log;
use strict;
use warnings;

use constant DEBUG => 1;

sub new {
  bless {}, shift;
};


# Add a document with a date range
# Returns the number of terms to index
sub add_range {
  my ($self, $doc_id, $range) = @_;
  my $field_date = Krawfish::Koral::Document::Field::DateRange->new(
    key => 'date',
    value => $range
  );

  if (DEBUG) {
    print_log('tk_dranges', 'Add range ' . $range . ' for id ' . $doc_id);
  };

  # Get all range terms
  my $i = 0;
  foreach my $term ($field_date->to_range_terms) {

    print_log('tk_dranges', ' +> ' . $term) if DEBUG;

    # Add doc_id to term list
    # Ignore a doc_id of 0!
    if ($doc_id) {
      $self->{$term} //= [];
      push @{$self->{$term}}, $doc_id;
    };
    $i++;
  };
  return $i;
};


# Run a query with a date range (currrently all-inclusive)
sub query {
  my $self = shift;
  my ($first, $second) = @_;

  my $query;
  if ($second) {

    if (DEBUG) {
      print_log('tk_dranges', 'Query range ' . $first . '--' . $second);
    };

    # Create inclusive daterange
    $query = Krawfish::Koral::Corpus::DateRange->new(
      Krawfish::Koral::Corpus::Field::Date->new('date')->geq($first),
      Krawfish::Koral::Corpus::Field::Date->new('date')->leq($second)
      );
  }
  else {
    print_log('tk_dranges', 'Query range ' . $first) if DEBUG;
    $query = Krawfish::Koral::Corpus::Field::Date->new('date')->eq($first),
  };

  my %match_docs = ();
  foreach my $tq ($query->to_term_query_array) {
    my $term = DATE_FIELD_PREF . $tq->to_neutral;

    print_log('tk_dranges', ' ?> ' . $term) if DEBUG;

    foreach (@{$self->{$term}}) {
      $match_docs{$_} = 1;
    };
  };

  return [sort keys %match_docs];
};


# Clear DateRange index
sub clear {
  my $self = shift;
  %{$self} = ();
  return 1;
};



1;
