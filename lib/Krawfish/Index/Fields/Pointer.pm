package Krawfish::Index::Fields::Pointer;
use Krawfish::Log;
use warnings;
use strict;

use constant DEBUG => 1;

# API:
# ->next_doc
# ->skip_doc($doc_id)
#
# ->doc_id                # The current doc_id
# ->pos                   # The current subtoken position
#
# ->fields                # All fields as terms
# ->fields(field_key_id*) # All fields with the key_id
# ->values(field_key_id)  # The value with the given key_id

sub new {
  my $class = shift;
  bless {
    list => shift,
    pos => 0,
    doc_id => -1,

    # Temporary until all is in one stream
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


sub next_doc;

sub close;

sub skip_doc {
  my ($self, $doc_id) = @_;
  if ($self->{doc_id} <= $doc_id && $doc_id < $self->freq) {

    if (DEBUG) {
      print_log('f_point', 'Get document for id ' . $doc_id);
    };

    $self->{doc_id} = $doc_id;
    my $doc = $self->{list}->doc($doc_id);

    $self->{doc} = $doc;
    $self->{pos} = 0;
    return 1;
  };
  return 0;
};

sub fields {
  my $self = shift;
  my @fields = ();
  my $doc = $self->{doc};

  my $current = $doc->[$self->{pos}];
  while ($current && $current ne 'EOF') {

    $self->{pos}++; # skip key_id

    my $type = $doc->[$self->{pos}++];

    push @fields, $doc->[$self->{pos}++];

    # Skip value
    $self->{pos}++ if $type eq 'int';
    $current = $doc->[$self->{pos}];
  };
  return @fields;
};

1;
