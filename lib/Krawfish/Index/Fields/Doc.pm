package Krawfish::Index::Fields::Doc;
use Krawfish::Log;
use warnings;
use strict;

# This is similar to Forward::Doc!

use constant DEBUG => 1;

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
    if (DEBUG) {
      print_log('fields_doc', 'Add ' . $_->to_string);
    };
    push @data, $_->key_id;     # Key data
    push @data, $_->type;       # Key type marker
                                # Store term or value!
    push @data, $_->term_id;
    push @data, $_->value if $_->type eq 'int';;
  };

  push @data, 'EOF';

  print_log('fields_doc', 'The fields are ' . join(',', map { defined $_ ? $_ : '?' } @data)) if DEBUG;

  bless \@data, $class;
};


sub to_stream;

1;
