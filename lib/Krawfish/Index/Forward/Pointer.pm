package Krawfish::Index::Forward::Pointer;
use Krawfish::Posting::Forward;
use Krawfish::Log;
use warnings;
use strict;

# WARNING:
#   This currently is not combined with live documents per default

use constant DEBUG => 1;

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

sub freq {
  my $freq = $_[0]->{list}->last_doc_id + 1;

  if (DEBUG) {
    print_log('fwd_point', "Doc frequency is $freq");
  };

  return $freq;
};

sub doc_id {
  $_[0]->{doc_id};
};


# The subtoken position
sub pos {
  $_[0]->{pos};
};


sub cur {
  $_[0]->{cur};
};

sub next_doc {
  ...
};


sub close {
  ...
};


sub skip_doc {
  my ($self, $doc_id) = @_;

  if (DEBUG) {
    print_log('fwd_point', "Skip from " . $self->{doc_id} . " to $doc_id");
  };

  if ($self->{doc_id} == $doc_id) {

    if (DEBUG) {
      print_log('fwd_point', 'Document already in position');
    };

    return 1;
  }
  elsif ($self->{doc_id} < $doc_id && $doc_id < $self->freq) {

    if (DEBUG) {
      print_log('fwd_point', 'Get document for id ' . $doc_id);
    };

    $self->{doc_id} = $doc_id;
    $self->{doc} = $self->{list}->doc($doc_id);
    $self->{cur} = 0;
    $self->{pos} = -1;

    delete $self->{current};
    delete $self->{prev};
    delete $self->{next};

    return 1;
  };
  return 0;
};


sub skip_pos {
  my ($self, $pos) = @_;

  return 0 if $pos < $self->{pos};

  if (DEBUG) {
    print_log('fwd_point', "Skip position to $pos");
  };

  # TODO:
  #   This should use skip lists!
  while ($pos > $self->{pos}) {
    $self->next or return 0;
  };

  return 1;
};


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
