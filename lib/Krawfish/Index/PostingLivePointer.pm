package Krawfish::Index::PostingLivePointer;
use parent 'Krawfish::Query';
use Krawfish::Log;
use strict;
use warnings;

# TODO:
#   The pointer should copy the list of deletes,
#   so a new delete during searching doesn't interfere with the list!

use constant {
  DEBUG => 0
};

# Points to a position in a live list

# TODO: Use Stream::Finger instead of PostingPointer


sub new {
  my $class = shift;
  my $self = bless {
    list_copy => [@{shift()}],
    last_doc_id => shift,
    pos => 0,
    doc_id => -1
  }, $class;

  print_log('live_p', 'Initialize live pointer') if DEBUG;

  # Set frequency
  $self->{freq} = $self->{last_doc_id} - scalar @{$self->{list_copy}};

  # Add stop marker to the list
  push(@{$self->{list_copy}}, $self->{last_doc_id} + 2);

  $self;
};


# Get frequency
sub freq {
  $_[0]->{freq};
};


# Get document identifier
sub doc_id {
  $_[0]->{doc_id};
};


# Forward position
sub next {
  my $self = shift;

  print_log('live_p', 'Next live doc id') if DEBUG;

  # Increment document id
  my $doc_id = ++$self->{doc_id};

  my $list = $self->{list_copy};

  # The position is either deleted or the current position is outside doc vector
  # There is a stop marker at the end of the deletion list.
  while ($doc_id >= $list->[$self->{pos}]) {

    print_log('live_p', 'Current doc_id is either deleted or beyond') if DEBUG;

    if ($doc_id == $list->[$self->{pos}]) {

      # Increment document id
      $doc_id = ++$self->{doc_id};

      if ($doc_id > $self->{last_doc_id}) {
        $self->{doc_id} = $self->{last_doc_id} + 1;
        print_log('live_p', 'doc_id has reached final position') if DEBUG;
        return;
      };
    };

    # Move forward in deletes list
    $self->{pos}++;
  };

  # Doc_id is not outside the document vector
  if ($doc_id <= $self->{last_doc_id}) {
    print_log('live_p', 'Current doc_id is fine') if DEBUG;
    return 1;
  };

  print_log('live_p', 'doc_id has reached final position') if DEBUG;
  $self->{doc_id} = $self->{last_doc_id} + 1;
  return;
};


sub next_doc {
  $_[0]->next;
};


sub skip_doc {
  my $self = shift;

  my $doc_id = shift;

  if ($doc_id > $self->{last_doc_id} || $doc_id < $self->{doc_id}) {
    $self->{doc_id} = $self->{last_doc_id} + 1;
    return;
  };

  my $list = $self->{list_copy};

  # Move through deletion list until doc_id is valid
  while ($list->[$self->{pos}] <= $doc_id) {

    # Requested document is deleted
    if ($list->[$self->{pos}] == $doc_id) {

      # Goto next doc
      $doc_id++;
    };

    # Move to next deletion list position
    $self->{pos}++;
  };

  # TODO: Can this happen?
  return if $doc_id > $self->{last_doc_id};

  # Set document id
  return $self->{doc_id} = $doc_id;
};

sub last_doc {
  $_[0]->{last_doc_id};
};

sub to_string {
  '[1]';
};

sub configuration {
  my $self = shift;
  my @del = @{$self->{list_copy}};
  my $pos = $del[$self->{pos}];

  my @list = ();

  for (my $i = 0; $i <= $self->{last_doc_id}; $i++) {
    if (defined $del[0] && $i == $del[0]) {
      push @list, '!' . ($i == $pos ? "[$i]" : $i);
      shift @del;
    }
    elsif ($i == $self->{doc_id}) {
      push @list, "<$i>";
    }
    else {
      push @list, $i;
    };
  };
  return join ',', @list;
};


sub freq_in_doc {
  1;
};


sub pos {
  return $_[0]->{pos};
};


# Does not return a posting, so it may be called differently
sub current {
  my $self = shift;

  # Document id beyond document vector
  # return if $self->{doc_id} > $self->last_doc;

  # Return document id
  return $self->{doc_id};
};


sub close {
  ...
};


1;


__END__
