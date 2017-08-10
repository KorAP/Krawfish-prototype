package Krawfish::Index::Fields::Doc;
use warnings;
use strict;

# This is similar to Forward::Doc!

sub new {
  my $class = shift;
  my $doc = shift;

  # Create fields
  my $fields = $doc->fields;

  # Sort fields by term identifiers
  # Should probably be part of the document
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


  bless \@data, $class;
};


sub to_stream;

1;
