package Krawfish::Posting::Forward;
use Krawfish::Log;
use strict;
use warnings;

# Posting in the Forward index

# THIS IS VERY SIMILAR TO Krawfish::Koral::Document::Subtoken

# API:
#   ->preceding_data   # The whitespace data before the subtoken
#   ->subterm_id       # The current subterm identifier
#   ->annotations      # Get all annotations as terms
#   ->annotations(
#     foundry          # TODO: Think of more complex options!
#   )

# TODO:
#   In Enrich::Context there is also
#   the need for something similar
#   with preceding bytes and term ids.
#   This may be a base class.
#   If this is splitted, the checks for stream
#   can be omitted.
#
# TODO:
#   There may also be the need for an annotation class,
#   so annotation data from the postingslist or the
#   forward stream can correctly be interpreted.
#   Or use Krawfish::Koral::Document::Annotation

use constant DEBUG => 0;


# Constructor
sub new {
  my $class = shift;

  # Contains term_id, preceding_data, cur and stream
  bless {@_}, $class;
};


# Get term id
sub doc_id {
  $_[0]->{doc_id};
};


# Get surface term id
sub term_id {
  $_[0]->{term_id};
};


# Get preceding data
# TODO:
#   Rename to 'preceding_enc' to be in line
#   with K::K::Document::Subtoken
sub preceding_data {
  $_[0]->{preceding_data} // '';
};


# Get stream (if available)
sub stream {
  $_[0]->{stream};
};


# Get annotations
sub annotations {
  my $self = shift;

  my @anno = ();

  # Get stream in case stream is initialized
  my $list = $self->stream or return;

  while ($list->[$self->{cur}] ne 'EOA') {
    $self->{cur} += 3; # skip foundry_id, layer_id, type
    my $anno_id = $list->[$self->{cur}++];
    my $data = $list->[$self->{cur}++];

    push @anno, [$anno_id, $data];
  };

  return @anno;
};


# Get a specific annotation
sub annotation {
  my ($self, $foundry_id, $layer_id, $anno_id) = @_;

  if (DEBUG) {
    print_log(
      'p_forward',
      "Find annotation for #$foundry_id/#$layer_id=#$anno_id"
    );
  };

  # Get stream in case stream is initialized
  my $list = $self->stream or return;

  my @anno = ();

  # Check annotations
  while ($list->[$self->{cur}] ne 'EOA') {

    if (DEBUG) {
      print_log(
        'p_forward',
        'Foundry is #' . $list->[$self->{cur}]
      );
    };

    # The annotation has the correct foundry
    if ($list->[$self->{cur}] == $foundry_id) {
      $self->{cur}++;

      # The annotation has the corrext layer
      if ($list->[$self->{cur}] == $layer_id) {
        $self->{cur}++;

        # Ignore type
        $self->{cur}++;

        # The annotation has the correct annotation
        if ($list->[$self->{cur}] == $anno_id) {
          $self->{cur}++;

          # Get data (for tokens, this is the end)
          my $data = $list->[$self->{cur}];
          push @anno, $data;

          # Move to next potentially valid annotation
          $self->{cur}++;
        }

        # The current anno id is beyond scope
        elsif ($list->[$self->{cur}] > $anno_id) {
          last;
        }

        # Check the next annotation
        else {
          $self->{cur}+=2; # Ignore data, anno_id
          $self->{cur}++; # Move to next
        }
      }

      # The layer is beyond scope
      elsif ($list->[$self->{cur}] > $layer_id) {
        last;
      }

      # Check next layer
      else {
        $self->{cur}+=3; # Ignore data, anno_id, layer, type
        $self->{cur}++; # Move to next
      }
    }

    # The foundry is beyond scope
    elsif ($list->[$self->{cur}] > $foundry_id) {
      last;
    }

    # Check next foundry
    else {
      $self->{cur}+=4; # Ignore data, anno_id, layer_id, foundry
      $self->{cur}++; # Move to next
    }
  };

  return \@anno;
};


# Stringification
sub to_string {
  my $str = '[' . ($_[0]->doc_id // '?') . ':#' . $_[0]->term_id;
  $str .= '$' . $_[0]->preceding_data if $_[0]->preceding_data;
  return $str .']';
};


1;
