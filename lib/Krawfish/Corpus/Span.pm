package Krawfish::Corpus::Span;
use strict;
use warnings;
use Role::Tiny::With;

with 'Krawfish::Corpus';

# Search for intratextual features

sub new {
  my $class = shift;
  return bless {
    query => shift,
    min => (shift // 1),
    max => shift,
    _init => undef
  }, $class;
};


# Clone query
sub clone {
  my $self = shift;
  __PACKAGE__->new(
    $self->{query}->clone,
    $self->{min},
    $self->{max}
  );
};


# Move to next document
sub next {
  my $self = shift;

  my $next;

  unless ($self->{_init}) {
    $self->{_init}++;

    $next = $self->{query}->next or return;
  }
  else {
    $next = $self->{query}->next_doc or return;
  };

  if ($self->{min} == 1 && !defined $self->{max}) {
    return $next;
  };

  # Count matches
  my $query = $self->{query};
  my $count = 1;
  my $init_current_doc_id = $query->current->doc_id;
  my $current_doc_id;


  while (1) {
    $query->next or return;

    $current_doc_id = $query->current->doc_id;

    # Check if it's still in the same document
    if ($current_doc_id == $init_current_doc_id) {
      $count++;
      if ($count >= $self->{min}) {
        return 1;
      }
    }
    else {
      $init_current_doc_id = $current_doc_id;
      $count = 1;
    }
  };

  return;
};


# Get current posting
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


# Return maximum frequency
sub max_freq {
  $_[0]->{query}->max_freq;
};


# stringification
sub to_string {
  my $str = 'span(' . $_[0]->{query}->to_string;
  if ($_[0]->{min} != 1 || defined $_[0]->{max}) {
    $str .= ',' . $_[0]->{min};
    $str .= ',' . $_[0]->{max} if $_[0]->{max};
  };
  return $str . ')';
};


1;
