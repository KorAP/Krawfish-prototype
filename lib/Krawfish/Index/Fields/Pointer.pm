package Krawfish::Index::Fields::Pointer;
use Krawfish::Koral::Document::FieldInt;
use Krawfish::Koral::Document::FieldStore;
use Krawfish::Koral::Document::FieldString;
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

# TODO:
#   Multiple aggregations (e.g. values and facets) will currently
#   use multiple pointers, though this could be optimized.

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


sub next_doc {
  warn 'Not supported';
};


sub close {
  ...
};


# Skip doc moves the pointer forward in the stream. Although currently
# there are multiple streams (one stream per doc), in the future there
# will only be one - that's why it can only move forward.
sub skip_doc {
  my ($self, $doc_id) = @_;
  if ($self->{doc_id} <= $doc_id && $doc_id < $self->freq) {

    if (DEBUG) {
      print_log('f_point', 'Get field list for doc_id ' . $doc_id);
    };

    $self->{doc_id} = $doc_id;
    my $doc = $self->{list}->doc($doc_id);

    $self->{doc} = $doc;
    $self->{pos} = 0;
    return $doc_id;
  };
  return -1;
};


# This returns only int-values - so it may need to be renamed
sub int_fields {
  my $self = shift;

  my @key_ids = @_;  # Need to be sorted in order!

  my $doc = $self->{doc};

  return if $doc == -1;

  my ($key_id, $type);
  my $key_pos = 0;

  # Collect values
  my @values = ();

  my $current = $doc->[$self->{pos}];
  while ($current && $current ne 'EOF') {

    unless (defined $key_ids[$key_pos]) {
      if (DEBUG) {
        print_log('f_point', 'There are no more fields to fetch ' .
                    'at keypos ' . $key_pos . ' in doc_id ' . $self->{doc_id});
      };
      last;
    };

    if ($current == $key_ids[$key_pos]) {

      # The structure [key_id, value] is necessary for multivalued fields!
      $key_id = $doc->[$self->{pos}++];
      $type = $doc->[$self->{pos}++];

      # Skip key term or value (in case of store)
      $self->{pos}++;

      # There is a value to aggregate
      if ($type eq 'int') {
        if (DEBUG) {
          print_log('f_point', "Found value for " . $key_ids[$key_pos] . ' at ' . $key_pos);
        };
        push @values, Krawfish::Koral::Document::FieldInt->new(
          key_id => $key_id,
          value => $doc->[$self->{pos}++]
        );
      };
    }

    # The requested key does not exist
    elsif ($current > $key_ids[$key_pos]) {
      # Ignore the key id
      $key_pos++;
      CORE::next;
    }

    # Ignore the field
    else {
      $self->{pos}++;
      $type = $doc->[$self->{pos}++];
      $self->{pos}++;
      $self->{pos}++ if $type eq 'int' || $type eq 'store'
    };

    # Remember the current field
    $current = $doc->[$self->{pos}];
  };

  return @values;
};


# Get all field term ids.
# If key ids are passed, they need to be in numerical order!
sub fields {
  my $self = shift;

  my @fields = ();
  my $doc = $self->{doc};

  return if $doc == -1;

  my ($type, $key_id);

  my $current = $doc->[$self->{pos}];

  # There are no key ids defined
  unless (@_ > 0) {
    while ($current && $current ne 'EOF') {

      push @fields, $self->_get_by_type($doc);
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
      print_log(
        'f_point',
        'Get fields for key ids ' . join(',', map { '#' . $_ } @key_ids)
      );
    };

    # There is a current field defined
    while ($current && $current ne 'EOF') {

      unless (defined $key_ids[$key_pos]) {
        if (DEBUG) {
          print_log('f_point', 'There are no more fields to fetch ' .
                      'at keypos ' . $key_pos . ' in doc_id ' . $self->{doc_id});
        };
        last;
      };

      # The requested key does not exist
      if ($current > $key_ids[$key_pos]) {
        # Ignore the key id
        $key_pos++;
        CORE::next;
      };


      # The key id matches the first id
      if ($current == $key_ids[$key_pos]) {
        push @fields, $self->_get_by_type($doc);

        if (DEBUG) {
          print_log('f_point', 'Found field ' .
                      $fields[-1]->to_string .
                      ' for key #' . $key_ids[$key_pos]);
        };
      }


      # Ignore the field
      else {
        $self->{pos}++;
        $type = $doc->[$self->{pos}++];
        $self->{pos}++ if $type ne 'store';
        $self->{pos}++ if $type eq 'int' || $type eq 'store';
      };


      # Remember the current field
      $current = $doc->[$self->{pos}];

      if (DEBUG) {
        print_log('f_point', 'New current key id is #' . $current);
      };
    };

  };
  return @fields;
};


sub _get_by_type {
  my ($self, $doc) = @_;

  my $key_id = $doc->[$self->{pos}++];

  my $type = $doc->[$self->{pos}++];

  # Read integer
  if ($type eq 'int') {
    return Krawfish::Koral::Document::FieldInt->new(
      key_id => $key_id,
      key_value_id => $doc->[$self->{pos}++],
      value => $doc->[$self->{pos}++]
    );
  }

  # read string
  elsif ($type eq 'string') {
    return Krawfish::Koral::Document::FieldString->new(
      key_id => $key_id,
      key_value_id => $doc->[$self->{pos}++]
    );
  }

  # read store
  elsif ($type eq 'store') {
    return Krawfish::Koral::Document::FieldStore->new(
      key_id => $key_id,
      value => $doc->[$self->{pos}++]
    );
  };
};


sub field_terms {
  my $self = shift;
  warn 'probably wrong!';
  return map { $_->term_id } $self->fields(@_);
};



1;
