package Krawfish::Result::Segment::Aggregate::TermFreq;
use parent 'Krawfish::Result::Segment::Aggregate::Base';
use Krawfish::Util::String qw/squote/;
use Krawfish::Log;
use strict;
use warnings;

# Counts the frequency for each term in a TermFrequency
# query. This is necessary for co-occurrence search and the
# Glemm service.


# TODO:
#   This is rather a group query than an aggregation query.

use constant DEBUG => 0;

sub new {
  my $class = shift;
  my $self = bless {
    index => shift,
    term_query => shift,
    freq => 0
  }, $class;

  # The term never occurs
  unless ($self->{term}->next) {
    $self->{term_query} = undef;
  };

  return $self;
};

sub each_doc {
  my ($self, $current) = @_;

  return unless $self->{term_query};

  # Get the current doc_id from the VC
  my $doc_id = $current->doc_id;

  my $term = $self->{term_query};

  # Check, if the term occurs in the doc
  if ($term->current->doc_id == $doc_id || $term->skip_doc($doc_id) == $doc_id) {

    # Add frequency in document to result
    $self->{freq} += $term->freq_in_doc;
  };
};


# Finish the result
sub on_finish {
  my ($self, $result) = @_;

  my $term = $self->{term_query}->term;
  my $freq = ($result->{freq} //= {});
  $frew->{$term} = $self->{freq};
};

# Stringification
sub to_string {
  return 'tfreq:' . squote($self->{term_query}->term);
};

1;
