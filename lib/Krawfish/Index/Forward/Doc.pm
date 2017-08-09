package Krawfish::Index::Forward::Doc;
use warnings;
use strict;

sub new {
  my $class = shift;
  my $doc = shift;

  # Create fields
  my $fields = $doc->fields;

  # Sort fields by term identifiers
  # Should probably be part of the doczument
  my @sorted_fields = sort {
    if ($a->key_id < $b->key_id) {
      return -1;
    }
    elsif ($a->key_id > $b->key_id) {
      return 1;
    }
    elsif ($a->term_id < $b->term_id) {
      return -1;
    }
    elsif ($a->term_id > $b->term_id) {
      return 1;
    }
    else {
      warn 'Multiple fields given!';
      return 0;
    };
  } @$fields;


  # Add field data
  my @data = ();
  foreach (@sorted_fields) {
    push @data, $_->key_id;     # Key data
    push @data, $_->type;       # Key type marker
                                # Store term or value!
    push @data, ($_->type eq 'int' ? $_->value : $_->term_id);
  };
  push @data, 'EOF';
  push @data, 0;           # Point to previous subtoken (should be xor)

  my $start_marker;

  # Add annotation data
  my $stream = $doc->stream;
  foreach my $subtoken (@$stream) {

    push @data, 0;           # Point to next subtoken (should be xor)
    $start_marker = $#data;

    push @data, $subtoken->term_id;
    push @data, $subtoken->preceding;

    my @sorted_annotations = sort {
      if ($a->foundry_id < $b->foundry_id) {
        -1;
      }
      elsif ($a->foundry_id > $b->foundry_id) {
        1;
      }
      elsif ($a->layer_id < $b->layer_id) {
        -1;
      }
      elsif ($a->layer_id > $b->layer_id) {
        1;
      }
      elsif ($a->term_id < $b->term_id) {
        -1;
      }
      elsif ($a->term_id > $b->term_id) {
        1;
      }
      else {
        0;
      };
    } @{$subtoken->annotations};

    # Add all annotations to the stream
    foreach (@sorted_annotations) {
      push @data, $_->foundry_id;
      push @data, $_->layer_id;
      push @data, $_->term_id;
      push @data, [@{$_->data}];
    };

    push @data, $start_marker;         # Point to previous subtoken
    $data[$start_marker] = $#data;     # Update last subtoken
  };

  bless {
    stream => \@data
  }, $class;
};




1;
