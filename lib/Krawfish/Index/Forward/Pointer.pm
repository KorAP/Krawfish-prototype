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
    pos => 0,
    doc_id => -1,

    current => undef,

    # Temporary
    doc => -1
  }, $class;
};

sub freq {
  $_[0]->{list}->last_doc_id + 1;
};

sub doc_id {
  $_[0]->{doc_id};
};

sub pos {
  $_[0]->{pos};
};

sub next_doc {
};


sub close {
  ...
};


sub skip_doc {
  my ($self, $doc_id) = @_;
  if ($self->{doc_id} <= $doc_id && $doc_id < $self->freq) {

    if (DEBUG) {
      print_log('fwd_point', 'Get document for id ' . $doc_id);
    };

    $self->{doc_id} = $doc_id;
    my $doc = $self->{list}->doc($doc_id);
    $self->{doc} = $doc;
    $self->{pos} = 0;

    delete $self->{current};
    delete $self->{prev};
    delete $self->{next};

    return 1;
  };
  return 0;
};


sub skip_pos {
  my ($self, $pos) = @_;
};


sub current {
  my $self = shift;

  # Return current
  return $self->{current} if $self->{current};

  my $doc = $self->{doc};

  my $pos = $self->pos;

  if (DEBUG) {
    print_log('fwd_point', "Point to subtoken at $pos is " . $doc->[$pos]);
  };

  if (DEBUG) {
    print_log('fwd_point', 'Doc is ' . $self->{doc}->to_string($self->{pos}));
  };

  # Establish subtoken
  $self->{current} = Krawfish::Posting::Forward->new(
    term_id        => $doc->[$pos++],
    preceding_data => $doc->[$pos++],
    pos            => $pos,
    stream         => $doc
  );

  $self->{pos} = $pos;

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
    $self->{prev} = $doc->[$self->{pos}++];
    $self->{next} = $doc->[$self->{pos}++];
  }

  else {

    # Get next token from data
    $self->{pos} = $self->{next};
    $self->{prev} = $doc->[$self->{pos}++];
    $self->{next} = $doc->[$self->{pos}++];
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
  $self->{pos} = $self->{prev};
  $self->{prev} = $doc->[$self->{pos}++];
  $self->{next} = $doc->[$self->{pos}++];

  if (DEBUG) {
    print_log('fwd_point', "Previous subtoken at " . $self->{prev});
    print_log('fwd_point', "Next subtoken at " . $self->{next});
  };

  $self->{current} = undef;
  return 1;
};



1;
