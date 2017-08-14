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


# Skip doc moves the pointer forward in the stream. Although currently
# there are multiple streams (one stream per doc), in the future there
# will only be one - that's why it can only move forward.
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
    return $doc_id;
  };
  return -1;
};


# Get all field term ids.
# If key ids are passed, they need to be in numerical order!
sub fields {
  my $self = shift;

  my @fields = ();
  my $doc = $self->{doc};
  my $type;

  my $current = $doc->[$self->{pos}];

  unless (@_ > 0) {
    while ($current && $current ne 'EOF') {

      # The structure [key_id, key] is necessary for multivalued fields!
      my $key_id = $self->{pos}++;

      $type = $doc->[$self->{pos}++];

      push @fields, [$key_id, $doc->[$self->{pos}++]];

      # Skip value
      $self->{pos}++ if $type eq 'int';
      $current = $doc->[$self->{pos}];
    };
  }

  # There are key ids given, that need to be in numerical order
  else {
    my @key_ids = @_;
    my $key_pos = 0;

    # TODO:
    #   Check treatment of wrongly sorted fields.

    if (DEBUG) {
      print_log('f_point', 'Get fields ' . join(',', @key_ids));
    };


    while ($current && $current ne 'EOF') {

      unless (defined $key_ids[$key_pos]) {
        if (DEBUG) {
          print_log('f_point', "There are no more fields to fetch at " . $key_pos);
        };
        last;
      };

      # The key id matches the first id
      if ($current == $key_ids[$key_pos]) {
        # The structure [key_id, key] is necessary for multivalued fields!
        $self->{pos}++;
        $type = $doc->[$self->{pos}++];
        my $field = $doc->[$self->{pos}++];
        push @fields, [$current, $field];

        if (DEBUG) {
          print_log('f_point', "Found field_id $field for " . $key_ids[$key_pos] . ' at ' . $key_pos);
        };

        $key_pos++;
      }

      # The requested key does not exist
      elsif ($current > $key_ids[$key_pos]) {
        # Ignore the key id
        $key_pos++;
        next;
      }

      # Ignore the field
      else {
        $self->{pos}++;
        $type = $doc->[$self->{pos}++];
        $self->{pos}++;
      };

      # Skip value
      $self->{pos}++ if $type eq 'int';

      # Remember the current field
      $current = $doc->[$self->{pos}];
    };

  };
  return @fields;
};




1;
