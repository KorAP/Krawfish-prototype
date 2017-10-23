package Krawfish::Corpus::Span;
use parent 'Krawfish::Corpus';
use strict;
use warnings;

# Search for intratextual features

sub new {
  my $class = shift;
  bless {
    query => shift,
    _init => undef
  }, $class;
};


# Clone query
sub clone {
  my $self = shift;
  __PACKAGE__->new(
    $self->{query}->clone
  );
};


# Move to next document
sub next {

  my $self = shift;

  unless ($self->{_init}) {
    $self->{_init}++;
    return $self->{query}->next;
  };
  return $self->{query}->next_doc;
};

sub current {
  my $self = shift;
  my $current = $self->{query}->current or return;
  return Krawfish::Posting->new(
    doc_id => $current->doc_id
  );
};


# Skip to target document
sub skip_doc {
  $_[0]->{query}->skip_doc($_[1]);
};


# stringification
sub to_string {
  'span(' . $_[0]->{query}->to_string . ')'
};


# Return maximum frequency
sub max_freq {
  $_[0]->{query}->max_freq;
};

1;
