package Krawfish::Corpus::Negation;
use Krawfish::Index::PostingsList;
use Krawfish::Posting::Doc;
use Krawfish::Query::Nothing;
use Krawfish::Log;
use strict;
use warnings;


# TODO: Remove in favor of WithOut!



use constant DEBUG => 0;

# TODO: Support deleted docs
# Use PostingsLive!

sub new {
  my ($class, $index, $query) = @_;

  bless {
    query => $query,
    doc_id => -1,
    last_doc_id => $index->last_doc
  }, $class;
};

sub _init {
  return if $_[0]->{init}++;
  if (DEBUG) {
    print_log('kq_neg', 'Initialize field') if DEBUG;
  };
  $_[0]->{query}->next;
};

sub next {
  my $self = shift;
  $self->_init;

  return unless defined $self->{doc_id};

  while (1) {
    $self->{doc_id}++;

    print_log('kq_neg', 'Check doc id ' . $self->{doc_id}) if DEBUG;

    my $check = $self->_check;
    return if $check == 0;
    return 1 if $check == 1;

    # Advance negative postings
    $self->{query}->next;
  };

#  print_log('vc_neg', 'Next "'.$self->term.'"') if DEBUG;
#
#  my $return = $self->{postings}->next;
#  if (DEBUG) {
#    print_log('field', ' - current is ' . $self->current) if $return;
#    print_log('field', ' - no current');
#  };
#  return $return;
};

sub _check {
  my $self = shift;

  my $next_neg = $self->{query}->current;

  # The current element is negated
  if ($next_neg && $self->{doc_id} == $next_neg->doc_id) {
    print_log('kq_neg', 'Current doc_id ' . $self->{doc_id} . ' is negated') if DEBUG;
    return -1
  }

  # Fine - and not at the end of the index
  elsif ($self->{doc_id} < $self->{last_doc_id}) {
    print_log('kq_neg', 'Current doc_id ' . $self->{doc_id} . ' is fine') if DEBUG;
    return 1;
  }

  # Reached the end of the index
  else {
    print_log('kq_neg', 'Current doc_id ' . $self->{doc_id} . ' is beyond index') if DEBUG;
    $self->{doc_id} = undef;
    return 0;
  };
}

sub current {
  my $self = shift;
  return if !defined $self->{doc_id} || $self->{doc_id} == -1;
  Krawfish::Posting::Doc->new(
    $self->{doc_id}
  );
}

sub freq {
  my $self = shift;
  $self->{last_doc_id} - $self->{query}->freq;
};

sub to_string {
  return "not(" . $_[0]->{query}->to_string . ")";
};

1;
