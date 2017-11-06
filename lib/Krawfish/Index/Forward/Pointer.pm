package Krawfish::Index::Forward::Pointer;
use Krawfish::Posting::Forward;
use Krawfish::Log;
use Krawfish::Util::Constants qw/NOMOREDOCS/;
use warnings;
use strict;

# Pointer in the list of documents.

# WARNING:
#   This currently is not combined with live documents per default

use constant {
  DEBUG => 0
};

# API:
# ->next_doc
# ->to_doc($doc_id)
# ->skip_pos($pos)
# ->next_subtoken (fails, when the document ends)
# ->prev_subtoken
#
# ->doc_id                # The current doc_id
# ->pos                   # The current subtoken position
#
# ->current               # The current subtoken object

# Constructor
sub new {
  my $class = shift;
  bless {
    list => shift,
    pos => -1,        # The subtoken position
    cur => 0,         # The cur position in the stream
    doc_id => -1,
    current => undef,
    prev => undef,
    next => undef,

    # Temporary until all is in one stream
    doc => -1
  }, $class;
};


# Get the number of documents in the index.
# Maybe passed in initialization phase
sub freq {
  my $freq = $_[0]->{list}->last_doc_id + 1;

  if (DEBUG) {
    print_log('fwd_point', "Doc frequency is $freq");
  };

  return $freq;
};


# Get current document id
sub doc_id {
  $_[0]->{doc_id};
};


# The subtoken position
sub pos {
  $_[0]->{pos};
};


# The cursor position
sub cur {
  $_[0]->{cur};
};


# Move to next document
sub next_doc {
  ...
};


# Potentially close stream
sub close {
  ...
};


# Skip to relevant document
sub skip_doc {
  my ($self, $target_doc_id) = @_;

  if (DEBUG) {
    print_log('fwd_point', "Skip from " . $self->{doc_id} . " to $target_doc_id");
  };

  # Pointer already in requested document
  if ($self->{doc_id} == $target_doc_id) {

    if (DEBUG) {
      print_log('fwd_point', 'Document already in position');
    };

    return $target_doc_id;
  }

  # Pointer needs to skip
  elsif ($self->{doc_id} < $target_doc_id && $target_doc_id < $self->freq) {

    if (DEBUG) {
      print_log('fwd_point', 'Get document for id ' . $target_doc_id);
    };

    $self->{doc_id} = $target_doc_id;
    $self->{doc} = $self->{list}->doc($target_doc_id);
    $self->{cur} = 0;
    $self->{pos} = -1;

    delete $self->{current};
    delete $self->{prev};
    delete $self->{next};

    return $target_doc_id;
  };
  return NOMOREDOCS;
};


# Skip to relevant position
sub skip_pos {
  my ($self, $target_pos) = @_;

  # TODO:
  #   There need to be a way to skip back in a document,
  #   though it's probably sufficient to
  #   go ->prev() without skipping
  return 0 if $target_pos < $self->{pos};

  if (DEBUG) {
    print_log('fwd_point', "Skip position to $target_pos");
  };

  # TODO:
  #   This should use skip lists!
  while ($target_pos > $self->{pos}) {
    $self->next or return 0;
  };

  return 1;
};


# Get the current token (a Krawfish::Posting::Forward)
sub current {
  my $self = shift;

  if (DEBUG) {
    print_log('fwd_point', "Get current forward posting");
  };

  # Return current
  return $self->{current} if $self->{current};

  my $doc = $self->{doc};

  my $cur = $self->cur;

  if (DEBUG) {
    print_log('fwd_point', "Point to subtoken at $cur is " . $doc->[$cur]);
  };

  if (DEBUG) {
    print_log('fwd_point', 'Doc is ' .
                $doc->to_string($cur));
  };

  # Establish subtoken
  $self->{current} = Krawfish::Posting::Forward->new(
    term_id        => $doc->[$cur++],
    preceding_data => $doc->[$cur++],
    cur            => $cur,
    stream         => $doc
  );

  $self->{cur} = $cur;

  return $self->{current};
};


# Move to the next posting
sub next {
  my $self = shift;

  # Initialize document
  if (!defined $self->{doc}) {
    $self->skip_doc(0);
  };

  my $doc = $self->{doc} or return;

  if (!defined $self->{next}) {

    # Move forward
    $self->{prev} = $doc->[$self->{cur}++];
    $self->{next} = $doc->[$self->{cur}++];
    $self->{pos} = 0;
  }

  else {

    # Get next token from data
    $self->{cur} = $self->{next};
    $self->{prev} = $doc->[$self->{cur}++];
    $self->{next} = $doc->[$self->{cur}++];
    $self->{pos}++;
  };

  if (DEBUG) {
    print_log('fwd_point', "Previous subtoken at " . $self->{prev});
    print_log('fwd_point', "Next subtoken at " . $self->{next});
  };

  $self->{current} = undef;
  return 1;
};


# Move to the previous token
sub prev {
  my $self = shift;

  # Not initialized
  return if !defined $self->{doc};
  return if !defined $self->{prev};

  # Get document
  my $doc = $self->{doc};

  # Get next token from data
  $self->{cur} = $self->{prev};
  $self->{pos}--;
  $self->{prev} = $doc->[$self->{cur}++];
  $self->{next} = $doc->[$self->{cur}++];

  if (DEBUG) {
    print_log('fwd_point', "Previous subtoken at " . $self->{prev});
    print_log('fwd_point', "Next subtoken at " . $self->{next});
  };

  $self->{current} = undef;
  return 1;
};


1;
