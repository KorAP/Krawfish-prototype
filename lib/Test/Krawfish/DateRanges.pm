package Test::Krawfish::DateRanges;
use Krawfish::Koral::Document::FieldDate;
use Krawfish::Koral::Corpus::Field::Date;
use Krawfish::Koral::Corpus::DateRange;
use Krawfish::Util::Constants qw/DATE_FIELD_PREF/;
use Krawfish::Log;
use strict;
use warnings;

use constant DEBUG => 0;

sub new {
  bless {}, shift;
};


# Add a document with a date range
sub add_range {
  my ($self, $doc_id, $range) = @_;
  my $field_date = Krawfish::Koral::Document::FieldDate->new(
    key => 'date',
    value => $range
  );

  if (DEBUG) {
    print_log('tk_dranges', 'Add range ' . $range . ' for id ' . $doc_id);
  };

  # Get all range terms
  my $i = 0;
  foreach my $term ($field_date->to_range_terms) {

    print_log('tk_dranges', ' > ' . $term) if DEBUG;

    # Add doc_id to term list
    $self->{$term} //= [];
    push @{$self->{$term}}, $doc_id;
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
  foreach my $tq ($query->to_term_queries) {
    my $term = DATE_FIELD_PREF . $tq->to_neutral;
    print_log('tk_dranges', 'Search for ' . $term) if DEBUG;
    foreach (@{$self->{$term}}) {
      $match_docs{$_} = 1;
    };
  };

  return [sort keys %match_docs];
};

1;
